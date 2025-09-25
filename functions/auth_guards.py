"""Authentication guards and decorators for Firebase Functions."""
from functools import wraps
from typing import Callable, Any
from firebase_functions import https_fn


def require_auth(func: Callable) -> Callable:
    """Decorator to require authentication for callable functions."""
    @wraps(func)
    def wrapper(req: https_fn.CallableRequest) -> Any:
        # Authentication guard
        if req.auth is None:
            raise https_fn.HttpsError('unauthenticated', 'Authentication required')
        
        return func(req)
    
    return wrapper


def get_user_id(req: https_fn.CallableRequest) -> str:
    """Get the authenticated user ID from the request."""
    if req.auth is None:
        raise https_fn.HttpsError('unauthenticated', 'Authentication required')
    
    return req.auth.uid


def get_user_email(req: https_fn.CallableRequest) -> str:
    """Get the authenticated user email from the request."""
    if req.auth is None:
        raise https_fn.HttpsError('unauthenticated', 'Authentication required')
    
    return req.auth.token.get('email', '')


class AuthContext:
    """Context class for authenticated user information."""
    
    def __init__(self, req: https_fn.CallableRequest):
        """Initialize auth context from request."""
        if req.auth is None:
            raise https_fn.HttpsError('unauthenticated', 'Authentication required')
        
        self.uid = req.auth.uid
        self.email = req.auth.token.get('email', '')
        self.name = req.auth.token.get('name', '')
        self.token = req.auth.token
