from django.urls import path

from .views import (
    AdminOrderListView,
    MyOrdersListView,
    OrderCreateView,
    OrderStatusUpdateView,
    ProductDetailView,
    ProductListCreateView,
)


urlpatterns = [
    # Catálogo de Productos / Comidas
    path('products', ProductListCreateView.as_view(), name='products-list-create'),
    path('products/', ProductListCreateView.as_view()),
    path('products/<int:pk>', ProductDetailView.as_view(), name='products-detail'),
    path('products/<int:pk>/', ProductDetailView.as_view()),

    # Pedidos (Cliente)
    path('orders', OrderCreateView.as_view(), name='orders-create'),
    path('orders/', OrderCreateView.as_view()),
    path('orders/mine', MyOrdersListView.as_view(), name='orders-mine'),
    path('orders/mine/', MyOrdersListView.as_view()),

    # Pedidos (Administración)
    path('admin/orders', AdminOrderListView.as_view(), name='admin-orders'),
    path('admin/orders/', AdminOrderListView.as_view()),
    path('orders/<int:pk>/status', OrderStatusUpdateView.as_view(), name='order-status'),
    path('orders/<int:pk>/status/', OrderStatusUpdateView.as_view()),
]
