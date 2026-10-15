# Re-export permissions from api package for backwards compatibility
from .api.permissions import IsAdminOrReadOnly, IsAdminUserRole

__all__ = [
    'IsAdminUserRole',
    'IsAdminOrReadOnly',
]