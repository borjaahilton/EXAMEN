from django.contrib import admin

from .models import Order, OrderItem, Product


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('subtotal',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'nombre', 'precio', 'disponible', 'creado_en')
    list_filter = ('disponible', 'creado_en')
    search_fields = ('nombre', 'descripcion')
    list_editable = ('precio', 'disponible')


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'cliente', 'estado', 'total', 'fecha')
    list_filter = ('estado', 'fecha')
    search_fields = ('cliente__email', 'cliente__first_name', 'cliente__last_name')
    list_editable = ('estado',)
    inlines = [OrderItemInline]


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('id', 'pedido', 'producto', 'cantidad', 'precio_unitario', 'subtotal')
    list_filter = ('producto',)