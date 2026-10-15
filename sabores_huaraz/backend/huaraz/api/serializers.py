from django.db import transaction
from rest_framework import serializers

from huaraz.models import Order, OrderItem, Product


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'

    def validate_precio(self, value):
        if value <= 0:
            raise serializers.ValidationError("El precio debe ser un monto positivo.")
        return value


class OrderItemSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.ReadOnlyField(source='producto.nombre')

    class Meta:
        model = OrderItem
        fields = ('id', 'producto', 'producto_nombre', 'cantidad', 'precio_unitario', 'subtotal')
        read_only_fields = ('precio_unitario', 'subtotal')


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)
    cliente_email = serializers.ReadOnlyField(source='cliente.email')

    class Meta:
        model = Order
        fields = ('id', 'cliente', 'cliente_email', 'fecha', 'estado', 'total', 'items')
        read_only_fields = ('id', 'cliente', 'fecha', 'total')

    def create(self, validated_data):
        items_data = validated_data.pop('items')
        cliente = self.context['request'].user

        with transaction.atomic():
            order = Order.objects.create(cliente=cliente, total=0.0)
            total_acumulado = 0

            for item_data in items_data:
                producto = item_data['producto']
                cantidad = item_data['cantidad']

                if not producto.disponible:
                    raise serializers.ValidationError(f"El plato '{producto.nombre}' está agotado.")
                if cantidad <= 0:
                    raise serializers.ValidationError("La cantidad debe ser mayor a 0.")

                subtotal = producto.precio * cantidad
                total_acumulado += subtotal

                OrderItem.objects.create(
                    pedido=order,
                    producto=producto,
                    cantidad=cantidad,
                    precio_unitario=producto.precio,
                    subtotal=subtotal
                )

            order.total = total_acumulado
            order.save()

        return order


class OrderStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ('estado',)
