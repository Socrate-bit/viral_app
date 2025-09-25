"""Firebase Functions for AI image generation and prompt suggestions."""
from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore
from typing import Dict, Any, List
import logging
import json
import os
import re

from gemini_client import GeminiClient
from auth_guards import require_auth, AuthContext
from prompts import FallbackSuggestions
from firestore_service import FirestoreService

# Configure logging to see errors in the console
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase Admin
initialize_app()

def _get_user_role(uid: str) -> str:
    """Get user role from Firestore."""
    try:
        db = firestore.client()
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            return user_doc.to_dict().get('role', 'normal')
        return 'normal'
    except Exception as e:
        logger.warning(f"Failed to get user role for {uid}: {e}")
        return 'normal'

def _check_and_deduct_tokens(auth: AuthContext, firestore_service: FirestoreService, tokens_needed: int) -> bool:
    """Check token balance and deduct if user is not admin/VIP. Returns True if operation should proceed."""
    user_role = _get_user_role(auth.uid)
    
    # Admin and VIP users bypass token requirements
    if user_role in ['admin', 'premium']:
        logger.info(f"User {auth.uid} has {user_role} role - bypassing token requirement")
        return True
    
    # Check token balance for normal users
    current_balance = firestore_service.get_user_balance(auth.uid)
    logger.info(f"User {auth.uid} current balance: {current_balance}, needs: {tokens_needed}")
    
    if current_balance < tokens_needed:
        logger.warning(f"Insufficient tokens for user {auth.uid}: {current_balance} < {tokens_needed}")
        raise https_fn.HttpsError('failed-precondition', 'Insufficient tokens', {
            'needsTokens': True, 
            'balance': current_balance,
            'required': tokens_needed
        })
    
    return True

def _check_generation_limits(auth: AuthContext, firestore_service: FirestoreService, images_to_generate: int) -> bool:
    """Check weekly generation limits for non-admin users. Returns True if operation should proceed."""
    user_role = _get_user_role(auth.uid)
    
    # Admin users bypass generation limits
    if user_role == 'admin':
        logger.info(f"User {auth.uid} has admin role - bypassing generation limit")
        return True
    
    # Check weekly generation limit for non-admin users
    if not firestore_service.check_weekly_generation_limit(auth.uid, images_to_generate):
        logger.warning(f"Weekly generation limit exceeded for user {auth.uid}")
        raise https_fn.HttpsError('failed-precondition', 'Weekly generation limit exceeded', {
            'weeklyLimitExceeded': True,
            'weeklyLimit': 300,
            'imagesRequested': images_to_generate
        })
    
    return True

def _deduct_tokens_after_success(auth: AuthContext, firestore_service: FirestoreService, tokens_to_deduct: int):
    """Deduct tokens after successful generation (only for normal users)."""
    user_role = _get_user_role(auth.uid)
    
    # Admin and VIP users don't get tokens deducted
    if user_role in ['admin', 'premium']:
        logger.info(f"User {auth.uid} has {user_role} role - skipping token deduction")
        return
    
    # Deduct tokens for normal users
    if not firestore_service.deduct_tokens(auth.uid, tokens_to_deduct):
        logger.warning(f"Failed to deduct {tokens_to_deduct} tokens for user {auth.uid} after successful generation")
    else:
        logger.info(f"Successfully deducted {tokens_to_deduct} tokens for user {auth.uid}")

def _validate_request_data(request_data: Dict[str, Any], required_fields: List[str]) -> None:
    """Validate request data has required fields."""
    if not request_data:
        logger.error("Invalid request data - no data provided")
        raise https_fn.HttpsError('invalid-argument', 'Invalid request data')
    
    missing_fields = []
    for field in required_fields:
        if not request_data.get(field):
            missing_fields.append(field)
    
    if missing_fields:
        logger.error(f"Missing required parameters: {missing_fields}")
        raise https_fn.HttpsError('invalid-argument', f'Missing required parameters: {", ".join(missing_fields)}')

@https_fn.on_call(secrets=["GOOGLE_AI_API_KEY"])
@require_auth
def generate_image(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Generate image using Google Gemini API with role-based token validation."""
    try:
        logger.info(f"Image generation request received for user: {req.auth.uid}")
        
        # Get user context
        auth = AuthContext(req)
        firestore_service = FirestoreService()
        
        # Validate request data
        _validate_request_data(req.data, ['originalImage', 'prompt'])
        
        # Check token balance (bypassed for admin/VIP)
        _check_and_deduct_tokens(auth, firestore_service, 1)
        
        # Check weekly generation limits (bypassed for admin)
        _check_generation_limits(auth, firestore_service, 1)
        
        # Extract parameters
        original_image_base64 = req.data.get('originalImage')
        prompt = req.data.get('prompt')
        reference_image_base64 = req.data.get('referenceImage')
        
        logger.info(f"Processing image generation with prompt: {prompt[:100]}...")
        
        # Generate image
        client = GeminiClient()
        image_data = client.generate_image(
            original_image_base64=original_image_base64,
            prompt=prompt,
            reference_image_base64=reference_image_base64
        )
        
        # Deduct token after successful generation (bypassed for admin/VIP)
        _deduct_tokens_after_success(auth, firestore_service, 1)
        
        # Increment generation counts
        firestore_service.increment_generation_counts(auth.uid, 1)
        
        # Get updated balance
        new_balance = firestore_service.get_user_balance(auth.uid)
        logger.info(f"Image generation successful for user {auth.uid}, new balance: {new_balance}")
        
        return {
            'imageData': image_data,
            'tokensRemaining': new_balance
        }
    
    except https_fn.HttpsError as e:
        logger.error(f"HttpsError in generate_image: {e.code} - {e.message}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error in generate_image: {str(e)}", exc_info=True)
        raise https_fn.HttpsError('internal', f'Failed to generate image: {str(e)}')

@https_fn.on_call(secrets=["GOOGLE_AI_API_KEY"])
@require_auth
def generate_prompt_suggestions(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Generate prompt suggestions using Google Gemini Vision API."""
    try:
        logger.info(f"Prompt suggestions request received for user: {req.auth.uid}")
        
        # Get user context
        auth = AuthContext(req)
        
        # Get request data
        request_data = req.data
        if not request_data:
            logger.error("Invalid request data for prompt suggestions")
            raise https_fn.HttpsError('invalid-argument', 'Invalid request data')
        
        # Extract image data
        image_base64 = request_data.get('imageData')
        if not image_base64:
            logger.error("Missing image data for prompt suggestions")
            raise https_fn.HttpsError('invalid-argument', 'Missing image data')
        
        # Use Gemini client to generate suggestions
        client = GeminiClient()
        suggestions = client.generate_suggestions(image_base64)
        
        logger.info(f"Generated {len(suggestions)} suggestions for user {auth.uid}")
        return {'suggestions': suggestions}
    
    except https_fn.HttpsError as e:
        logger.error(f"HttpsError in generate_prompt_suggestions: {e.code} - {e.message}")
        raise
    except Exception as e:
        logger.error(f"Error in generate_prompt_suggestions: {str(e)}", exc_info=True)
        # Return fallback suggestions if everything fails
        fallback_suggestions = FallbackSuggestions.get_fallback_suggestions()
        logger.info(f"Returning fallback suggestions for user {req.auth.uid}")
        return {'suggestions': fallback_suggestions}

@https_fn.on_request()
def superwall_webhook(req: https_fn.Request) -> https_fn.Response:
    """Handle Superwall webhook events for purchases and subscriptions."""
    try:
        logger.info("Superwall webhook received")
        
        # Verify webhook signature for security (optional but recommended)
        expected_secret = "95C4E7C2FA8FA2BA387114C171A19"  # Set this in Superwall dashboard
        webhook_secret = req.headers.get('X-Superwall-Secret')
        
        if expected_secret and webhook_secret != expected_secret:
            logger.warning("Webhook verification failed - invalid secret")
            return https_fn.Response("Unauthorized", status=401)
        
        # Parse webhook payload
        webhook_data = req.get_json()
        if not webhook_data:
            logger.error("Invalid webhook payload - no JSON data")
            return https_fn.Response("Invalid payload", status=400)
        
        logger.info(f"Webhook data: {json.dumps(webhook_data, indent=2)}")
        
        # Extract event information from the actual Superwall payload structure
        event_type = webhook_data.get('type')
        event_data = webhook_data.get('data', {})
        
        # Extract user ID from originalAppUserId and remove Superwall alias prefix
        original_app_user_id = event_data.get('originalAppUserId', '')
        if original_app_user_id.startswith('$SuperwallAlias:'):
            user_id = original_app_user_id.replace('$SuperwallAlias:', '')
        else:
            user_id = original_app_user_id
            
        if not user_id:
            logger.error(f"No user ID found in webhook: {webhook_data}")
            return https_fn.Response("No user ID", status=400)
        
        # Get product ID
        product_id = event_data.get('productId', '')
        
        logger.info(f"Processing event {event_type} for user {user_id}, product: {product_id}")
        
        firestore_service = FirestoreService()
        
        # Handle different event types based on actual Superwall event types
        if event_type in ['subscription_start', 'initial_purchase', 'trial_start']:
            # New subscription or trial
            firestore_service.update_subscription_status(
                uid=user_id,
                status='active',
                product_id=product_id,
                grant_tokens=True
            )
            logger.info(f"Subscription started for user {user_id}: {product_id}")
            
        elif event_type == 'renewal':
            # Subscription renewal - grant tokens
            firestore_service.update_subscription_status(
                uid=user_id,
                status='active',
                product_id=product_id,
                grant_tokens=True
            )
            logger.info(f"Subscription renewed for user {user_id}: {product_id}")
            
        elif event_type in ['cancellation', 'subscription_cancel']:
            # Subscription canceled
            firestore_service.update_subscription_status(
                uid=user_id,
                status='canceled',
                grant_tokens=False
            )
            logger.info(f"Subscription canceled for user {user_id}")
            
        elif event_type in ['expiration', 'subscription_expire']:
            # Subscription expired
            firestore_service.update_subscription_status(
                uid=user_id,
                status='expired',
                grant_tokens=False
            )
            logger.info(f"Subscription expired for user {user_id}")
            
        elif event_type in ['non_consumable_purchase', 'consumable_purchase']:
            # Token pack purchase
            # Map product IDs to token amounts (update these with your actual product IDs)
            token_amounts = {
                'reeys.tokens.200': 200,
                'reeys.tokens.500': 500,
                'reeys.tokens.2000': 2000,
                # Add your actual token pack product IDs here
            }
            
            token_amount = token_amounts.get(product_id, 0)
            if token_amount > 0:
                firestore_service.add_tokens(
                    uid=user_id,
                    amount=token_amount,
                    source='token_pack'
                )
                logger.info(f"Token pack purchased for user {user_id}: {product_id} = {token_amount} tokens")
            else:
                logger.warning(f"Unknown product ID for token pack: {product_id}")
        
        elif event_type == 'refund':
            # Handle refund - you might want to deduct tokens or mark subscription as refunded
            logger.info(f"Refund event for user {user_id}, product: {product_id}")
            
            # Optional: Deduct tokens for refunded token packs
            token_amounts = {
                'reeys.tokens.200': 200,
                'reeys.tokens.500': 500,
                'reeys.tokens.2000': 2000,
            }
            
            if product_id in token_amounts:
                # This was a token pack refund - you might want to deduct tokens
                # firestore_service.deduct_tokens(user_id, token_amounts[product_id])
                logger.info(f"Token pack refunded: {product_id}")
            else:
                # This was a subscription refund
                firestore_service.update_subscription_status(
                    uid=user_id,
                    status='refunded',
                    grant_tokens=False
                )
                logger.info(f"Subscription refunded for user {user_id}")
            
        else:
            logger.warning(f"Unknown event type: {event_type}")
        
        return https_fn.Response("OK", status=200)
        
    except Exception as e:
        logger.error(f"Webhook error: {str(e)}", exc_info=True)
        return https_fn.Response(f"Error: {str(e)}", status=500)

@https_fn.on_call()
@require_auth
def handle_first_time_user(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Initialize first-time user with secure token allocation and role assignment."""
    try:
        logger.info(f"First-time user initialization request for user: {req.auth.uid}")
        
        # Get user context
        auth = AuthContext(req)
        firestore_service = FirestoreService()
        
        # Get request data
        request_data = req.data or {}
        user_email = request_data.get('email') or auth.token.get('email')
        user_name = request_data.get('name') or auth.token.get('name')
        
        # Check if user already exists
        db = firestore.client()
        user_doc_ref = db.collection('users').document(auth.uid)
        user_doc = user_doc_ref.get()
        
        if user_doc.exists:
            logger.info(f"User {auth.uid} already initialized")
            return {
                'success': True,
                'message': 'User already initialized',
                'isNewUser': False
            }
        
        # Determine role: check if email is in premium_list
        role = 'normal'  # default
        if user_email:
            premium_query = db.collection('premium_list').where('email', '==', user_email).limit(1).get()
            if premium_query:
                role = 'premium'
                logger.info(f"User {auth.uid} ({user_email}) granted premium role")
        
        # Initialize user with secure token allocation
        welcome_tokens = 5  # Secure default amount
        user_data = {
            'balance': welcome_tokens,
            'subscriptionStatus': 'none',
            'subscriptionProductId': None,
            'lastUpdated': firestore.SERVER_TIMESTAMP,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'role': role,
            'email': user_email,
            'name': user_name,
            'totalGenerated': 0,
            'weeklyGenerated': 0,
            'weekStartDate': firestore.SERVER_TIMESTAMP,
        }
        
        # Create user document
        user_doc_ref.set(user_data)
        
        # Record welcome token transaction
        firestore_service._record_transaction(
            uid=auth.uid,
            event='welcome_bonus', 
            amount=welcome_tokens,
            description=f'Welcome bonus for new user: {role} role'
        )
        
        logger.info(f"Successfully initialized user {auth.uid} with role {role} and {welcome_tokens} tokens")
        
        return {
            'success': True,
            'message': 'User initialized successfully',
            'isNewUser': True,
            'role': role,
            'welcomeTokens': welcome_tokens,
            'balance': welcome_tokens
        }
        
    except Exception as e:
        logger.error(f"Error initializing first-time user {req.auth.uid}: {str(e)}", exc_info=True)
        raise https_fn.HttpsError('internal', f'Failed to initialize user: {str(e)}')

@https_fn.on_call(secrets=["GOOGLE_AI_API_KEY"])
@require_auth
def generate_pack_images(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Generate multiple images from a pack using Google Gemini API with role-based token validation."""
    try:
        logger.info(f"Pack generation request received for user: {req.auth.uid}")
        
        # Get user context
        auth = AuthContext(req)
        firestore_service = FirestoreService()
        
        # Validate request data
        _validate_request_data(req.data, ['originalImage', 'packId'])
        
        # Extract parameters
        original_image_base64 = req.data.get('originalImage')
        pack_id = req.data.get('packId')
        
        # Get pack data from Firestore
        db = firestore.client()
        pack_doc = db.collection('packs').document(pack_id).get()
        
        if not pack_doc.exists:
            logger.error(f"Pack not found: {pack_id}")
            raise https_fn.HttpsError('not-found', 'Pack not found')
        
        pack_data = pack_doc.to_dict()
        prompts = pack_data.get('prompt', [])
        
        if not prompts:
            logger.error(f"No prompts found in pack: {pack_id}")
            raise https_fn.HttpsError('invalid-argument', 'Pack has no prompts')
        
        # Check token balance (bypassed for admin/VIP)
        tokens_needed = len(prompts)
        _check_and_deduct_tokens(auth, firestore_service, tokens_needed)
        
        # Check weekly generation limits (bypassed for admin)
        _check_generation_limits(auth, firestore_service, len(prompts))
        
        logger.info(f"Generating {len(prompts)} images for pack: {pack_data.get('name')}")
        
        # Use Gemini client to generate all images in parallel
        import concurrent.futures
        import functools
        
        client = GeminiClient()
        generated_images = []
        
        def generate_single_image(index_prompt_tuple):
            i, prompt = index_prompt_tuple
            try:
                logger.info(f"Generating image {i+1}/{len(prompts)}: {prompt[:100]}...")
                image_data = client.generate_image(
                    original_image_base64=original_image_base64,
                    prompt=prompt,
                    reference_image_base64=None
                )
                
                # Save image to Firebase Storage and Firestore
                image_url, doc_id = firestore_service.save_image_to_firebase(image_data, auth.uid, prompt)
                
                return {
                    'imageUrl': image_url,
                    'prompt': prompt,
                    'index': i,
                    'documentId': doc_id
                }
            except Exception as e:
                logger.error(f"Failed to generate image {i+1}: {str(e)}")
                return None
        
        # Generate images in parallel using ThreadPoolExecutor
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
            # Submit all tasks
            future_to_index = {
                executor.submit(generate_single_image, (i, prompt)): i 
                for i, prompt in enumerate(prompts)
            }
            
            # Collect results
            for future in concurrent.futures.as_completed(future_to_index):
                result = future.result()
                if result is not None:
                    generated_images.append(result)
        
        # Sort results by index to maintain order
        generated_images.sort(key=lambda x: x['index'])
        
        if not generated_images:
            raise https_fn.HttpsError('internal', 'Failed to generate any images')
        
        # Deduct tokens after successful generation (bypassed for admin/VIP)
        tokens_to_deduct = len(generated_images)
        _deduct_tokens_after_success(auth, firestore_service, tokens_to_deduct)
        
        # Increment generation counts
        firestore_service.increment_generation_counts(auth.uid, len(generated_images))
        
        # Get updated balance
        new_balance = firestore_service.get_user_balance(auth.uid)
        logger.info(f"Pack generation successful for user {auth.uid}, {len(generated_images)} images generated, new balance: {new_balance}")
        
        return {
            'images': generated_images,
            'packName': pack_data.get('name'),
            'tokensRemaining': new_balance,
            'generatedCount': len(generated_images),
            'totalPrompts': len(prompts)
        }
    
    except https_fn.HttpsError as e:
        logger.error(f"HttpsError in generate_pack_images: {e.code} - {e.message}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error in generate_pack_images: {str(e)}", exc_info=True)
        raise https_fn.HttpsError('internal', f'Failed to generate pack images: {str(e)}')
