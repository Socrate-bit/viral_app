"""Firestore service for token and subscription management."""
from firebase_admin import firestore, storage
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, Tuple
import logging
import base64
import uuid

logger = logging.getLogger(__name__)

class FirestoreService:
    def __init__(self):
        self.db = firestore.client()
    
    def get_user_balance(self, uid: str) -> int:
        """Get current token balance for user."""
        try:
            doc_ref = self.db.collection('users').document(uid)
            doc = doc_ref.get()
            
            if not doc.exists:
                # Create new user document with default values
                self._create_user_document(uid)
                return 0
            
            data = doc.to_dict()
            return data.get('balance', 0)
        except Exception as e:
            logger.error(f"Failed to get user balance for {uid}: {str(e)}")
            raise
    
    def deduct_tokens(self, uid: str, amount: int) -> bool:
        """
        Deduct tokens from user balance.
        Returns True if successful, False if insufficient balance.
        """
        try:
            doc_ref = self.db.collection('users').document(uid)
            
            # Get current document
            doc = doc_ref.get()
            
            if not doc.exists:
                self._create_user_document(uid)
                return False
            
            current_balance = doc.to_dict().get('balance', 0)
            
            if current_balance < amount:
                return False
            
            # Use Firestore increment for atomic operation
            try:
                doc_ref.update({
                    'balance': firestore.Increment(-amount),
                    'lastUpdated': datetime.utcnow()
                })
                
                # Record transaction after successful deduction
                self._record_transaction(uid, 'deduction', -amount, f'Image generation: {amount} tokens')
                return True
                
            except Exception as e:
                logger.error(f"Failed to update balance for {uid}: {str(e)}")
                return False
            
        except Exception as e:
            logger.error(f"Failed to deduct tokens for {uid}: {str(e)}")
            raise
    
    def add_tokens(self, uid: str, amount: int, source: str = 'purchase') -> None:
        """Add tokens to user balance."""
        try:
            doc_ref = self.db.collection('users').document(uid)
            
            # Check if document exists, create if it doesn't
            doc = doc_ref.get()
            if not doc.exists:
                self._create_user_document(uid)
            
            doc_ref.update({
                'balance': firestore.Increment(amount),
                'lastUpdated': datetime.utcnow()
            })
            
            # Record transaction
            self._record_transaction(uid, source, amount, f'Tokens added: {amount} from {source}')
            
        except Exception as e:
            logger.error(f"Failed to add tokens for {uid}: {str(e)}")
            raise
    
    def update_subscription_status(
        self, 
        uid: str, 
        status: str, 
        product_id: str = None,
        grant_tokens: bool = True
    ) -> None:
        """Update user subscription status and optionally grant tokens."""
        try:
            doc_ref = self.db.collection('users').document(uid)
            
            # Check if document exists, create if it doesn't
            doc = doc_ref.get()
            if not doc.exists:
                self._create_user_document(uid)
            
            update_data = {
                'subscriptionStatus': status,
                'lastUpdated': datetime.utcnow()
            }
            
            if product_id:
                update_data['subscriptionProductId'] = product_id
            
            # Grant tokens for new active subscriptions
            if status == 'active' and grant_tokens:
                update_data['balance'] = firestore.Increment(140)  # Weekly tokens
                update_data['lastTokenAdd'] = datetime.utcnow()
                
                # Record transaction
                self._record_transaction(uid, 'subscription', 140, f'Subscription tokens: {product_id}')
            
            doc_ref.update(update_data)
            
        except Exception as e:
            logger.error(f"Failed to update subscription for {uid}: {str(e)}")
            raise
    
    def should_refill_subscription_tokens(self, uid: str) -> bool:
        """Check if user should receive weekly subscription token refill."""
        try:
            doc_ref = self.db.collection('users').document(uid)
            doc = doc_ref.get()
            
            if not doc.exists:
                return False
            
            data = doc.to_dict()
            
            # Check if subscription is active
            if data.get('subscriptionStatus') != 'active':
                return False
            
            # Check last token add time
            last_token_add = data.get('lastTokenAdd')
            if not last_token_add:
                return True
            
            # Convert to datetime if it's a Firestore timestamp
            if hasattr(last_token_add, 'date'):
                last_token_add = last_token_add.date()
            
            # Check if a week has passed
            one_week_ago = datetime.utcnow() - timedelta(days=7)
            return last_token_add < one_week_ago
            
        except Exception as e:
            logger.error(f"Failed to check refill status for {uid}: {str(e)}")
            return False
    
    def refill_subscription_tokens(self, uid: str) -> bool:
        """Refill subscription tokens if eligible. Returns True if tokens were added."""
        try:
            if not self.should_refill_subscription_tokens(uid):
                return False
            
            doc_ref = self.db.collection('users').document(uid)
            doc_ref.update({
                'balance': firestore.Increment(140),
                'lastTokenAdd': datetime.utcnow(),
                'lastUpdated': datetime.utcnow()
            })
            
            # Record transaction
            self._record_transaction(uid, 'subscription_refill', 140, 'Weekly subscription token refill')
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to refill subscription tokens for {uid}: {str(e)}")
            raise
    
    def _create_user_document(self, uid: str) -> None:
        """Create a new user document with default values."""
        doc_ref = self.db.collection('users').document(uid)
        doc_ref.set({
            'balance': 0,
            'subscriptionStatus': 'none',
            'subscriptionProductId': None,
            'lastUpdated': datetime.utcnow(),
            'lastTokenAdd': None,
            'totalGenerated': 0,
            'weeklyGenerated': 0,
            'weekStartDate': datetime.utcnow()
        })
    
    def save_image_to_firebase(self, image_data_base64: str, user_id: str, prompt: str) -> Tuple[str, str]:
        """Save image to Firebase Storage and Firestore, return (image_url, document_id)."""
        try:
            # Decode base64 image
            image_bytes = base64.b64decode(image_data_base64)
            
            # Generate unique filename
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_id = str(uuid.uuid4())[:8]
            filename = f"user_images/{user_id}/{timestamp}_{unique_id}.jpg"
            
            # Upload to Firebase Storage
            bucket = storage.bucket()
            blob = bucket.blob(filename)
            blob.upload_from_string(image_bytes, content_type='image/jpeg')
            
            # Make the blob publicly accessible
            blob.make_public()
            image_url = blob.public_url
            
            # Save metadata to Firestore
            doc_ref = self.db.collection('user_images').add({
                'userId': user_id,
                'imageUrl': image_url,
                'fileName': filename,
                'prompts': [prompt],
                'createdAt': firestore.SERVER_TIMESTAMP,
            })
            
            logger.info(f"Successfully saved image for user {user_id}: {image_url}")
            return image_url, doc_ref[1].id
            
        except Exception as e:
            logger.error(f"Failed to save image to Firebase: {str(e)}")
            raise

    def check_weekly_generation_limit(self, uid: str, images_to_generate: int) -> bool:
        """Check if user can generate the requested number of images within weekly limit."""
        try:
            doc_ref = self.db.collection('users').document(uid)
            doc = doc_ref.get()
            
            if not doc.exists:
                self._create_user_document(uid)
                return images_to_generate <= 300
            
            data = doc.to_dict()
            
            # Reset weekly count if a new week has started
            self._reset_weekly_count_if_needed(uid, data)
            
            # Get current weekly count (refresh data after potential reset)
            doc = doc_ref.get()
            data = doc.to_dict()
            current_weekly = data.get('weeklyGenerated', 0)
            
            # Check if adding new images would exceed limit
            return (current_weekly + images_to_generate) <= 300
            
        except Exception as e:
            logger.error(f"Failed to check weekly generation limit for {uid}: {str(e)}")
            return False
    
    def increment_generation_counts(self, uid: str, count: int) -> None:
        """Increment both total and weekly generation counts."""
        try:
            doc_ref = self.db.collection('users').document(uid)
            
            # Check if document exists, create if it doesn't
            doc = doc_ref.get()
            if not doc.exists:
                self._create_user_document(uid)
            
            # Reset weekly count if needed before incrementing
            data = doc.to_dict()
            self._reset_weekly_count_if_needed(uid, data)
            
            # Increment counters
            doc_ref.update({
                'totalGenerated': firestore.Increment(count),
                'weeklyGenerated': firestore.Increment(count),
                'lastUpdated': datetime.utcnow()
            })
            
            logger.info(f"Incremented generation counts for {uid}: +{count}")
            
        except Exception as e:
            logger.error(f"Failed to increment generation counts for {uid}: {str(e)}")
            raise
    
    def _reset_weekly_count_if_needed(self, uid: str, user_data: Dict[str, Any]) -> None:
        """Reset weekly generation count if a new week has started."""
        try:
            week_start_date = user_data.get('weekStartDate')
            if not week_start_date:
                # No week start date, set it to now
                doc_ref = self.db.collection('users').document(uid)
                doc_ref.update({
                    'weekStartDate': datetime.utcnow(),
                    'weeklyGenerated': 0
                })
                return
            
            # Convert Firestore timestamp to datetime if needed
            if hasattr(week_start_date, 'date'):
                # This is a Firestore timestamp, convert to datetime
                week_start_date = week_start_date.date()
            
            # Ensure we're comparing the same types
            current_time = datetime.utcnow()
            one_week_ago = current_time - timedelta(days=7)
            
            # Convert both to datetime for comparison
            if isinstance(week_start_date, datetime):
                week_start_datetime = week_start_date
            else:
                # If it's a date, convert to datetime at start of day
                week_start_datetime = datetime.combine(week_start_date, datetime.min.time())
            
            if week_start_datetime < one_week_ago:
                # Reset weekly count and update week start date
                doc_ref = self.db.collection('users').document(uid)
                doc_ref.update({
                    'weekStartDate': current_time,
                    'weeklyGenerated': 0,
                    'lastUpdated': current_time
                })
                logger.info(f"Reset weekly generation count for user {uid}")
            
        except Exception as e:
            logger.error(f"Failed to reset weekly count for {uid}: {str(e)}")
            # Don't raise - this shouldn't break the main operation

    def _record_transaction(self, uid: str, event: str, amount: int, description: str = None) -> None:
        """Record a transaction in the user's transaction history."""
        try:
            transaction_data = {
                'event': event,
                'amount': amount,
                'timestamp': datetime.utcnow()
            }
            
            if description:
                transaction_data['description'] = description
            
            self.db.collection('users').document(uid).collection('transactions').add(transaction_data)
            
        except Exception as e:
            logger.error(f"Failed to record transaction for {uid}: {str(e)}")
            # Don't raise - transaction recording failure shouldn't break the main operation
