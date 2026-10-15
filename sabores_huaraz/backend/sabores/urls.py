from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from authentication.views import LoginView, RegisterView


def api_root(request):
    return JsonResponse({
        'proyecto': 'Sabores de Huaraz',
        'descripcion': 'API REST para App Movil y Administracion',
        'version': '1.0',
        'servidor': 'activo',
        'rutas_disponibles': {
            'catalogo_platos': '/products',
            'autenticacion_login': '/auth/login',
            'registro_cliente': '/auth/register',
            'crear_pedido': '/orders',
            'mis_pedidos_cliente': '/orders/mine',
            'pedidos_admin': '/admin/orders',
            'panel_web_admin': '/admin/',
        }
    })


urlpatterns = [
    # Inicio / Estado de la API
    path('', api_root, name='api-root'),

    # Autenticación requerida
    path('auth/register', RegisterView.as_view(), name='auth-register'),
    path('auth/register/', RegisterView.as_view()),
    path('auth/login', LoginView.as_view(), name='token_obtain_pair'),
    path('auth/login/', LoginView.as_view()),
    path('auth/refresh', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/refresh/', TokenRefreshView.as_view()),

    # Endpoints de restaurante (App huaraz - incluye /admin/orders)
    path('', include('huaraz.urls')),
    path('api/', include('huaraz.api.urls')),
    path('api/comidas/', include('huaraz.api.urls')),

    # Panel Django Admin
    path('admin/', admin.site.urls),
]