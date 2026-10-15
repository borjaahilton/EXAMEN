# Re-export views from api package for backwards compatibility
from .api.views import (
    AdminOrderListView,
    MyOrdersListView,
    OrderCreateView,
    OrderStatusUpdateView,
    ProductDetailView,
    ProductListCreateView,
)

__all__ = [
    'ProductListCreateView',
    'ProductDetailView',
    'OrderCreateView',
    'MyOrdersListView',
    'AdminOrderListView',
    'OrderStatusUpdateView',
]