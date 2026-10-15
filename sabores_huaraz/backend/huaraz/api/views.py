from rest_framework import generics, permissions

from huaraz.models import Order, Product
from .permissions import IsAdminOrReadOnly, IsAdminUserRole
from .serializers import (
    OrderSerializer,
    OrderStatusUpdateSerializer,
    ProductSerializer,
)


# 1. Catálogo de Comidas: GET todos (o activos), POST solo Admin
class ProductListCreateView(generics.ListCreateAPIView):
    serializer_class = ProductSerializer
    permission_classes = [IsAdminOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and user.rol == 'admin':
            return Product.objects.all().order_by('-id')
        return Product.objects.filter(disponible=True).order_by('nombre')


# 2. Detalle y Actualización de Comida (Admin)
class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsAdminUserRole]


# 3. Crear pedido (Cliente autenticado)
class OrderCreateView(generics.CreateAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]


# 4. Historial del Cliente actual (/orders/mine)
class MyOrdersListView(generics.ListAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(cliente=self.request.user).order_by('-fecha')


# 5. Listado de todos los pedidos para el Panel Web (Admin)
class AdminOrderListView(generics.ListAPIView):
    queryset = Order.objects.all().order_by('-fecha')
    serializer_class = OrderSerializer
    permission_classes = [IsAdminUserRole]


# 6. Cambiar estado de un pedido (Admin)
class OrderStatusUpdateView(generics.UpdateAPIView):
    queryset = Order.objects.all()
    serializer_class = OrderStatusUpdateSerializer
    permission_classes = [IsAdminUserRole]
