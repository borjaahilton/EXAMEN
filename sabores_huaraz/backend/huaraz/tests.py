from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from huaraz.models import Order, Product


User = get_user_model()


class SaboresHuarazAPITests(APITestCase):
    def setUp(self):
        # Crear Admin y Cliente
        self.admin_user = User.objects.create_user(
            username='admin@sabores.com',
            email='admin@sabores.com',
            password='123',
            first_name='Admin',
            last_name='User',
            rol='admin',
            is_staff=True,
        )
        self.client_user = User.objects.create_user(
            username='cliente@sabores.com',
            email='cliente@sabores.com',
            password='123',
            first_name='Cliente',
            last_name='User',
            rol='cliente',
        )

        # Crear Plato Inicial
        self.product1 = Product.objects.create(
            nombre='Picante de Cuy',
            descripcion='Plato tipico huaracino',
            precio=35.00,
            disponible=True,
        )
        self.product_agotado = Product.objects.create(
            nombre='Pachamanca Agotada',
            descripcion='No disponible hoy',
            precio=40.00,
            disponible=False,
        )

    def test_01_login_admin_returns_token_and_rol(self):
        url = '/auth/login'
        data = {'email': 'admin@sabores.com', 'password': '123'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data.get('rol'), 'admin')

    def test_02_register_client(self):
        url = '/auth/register'
        data = {
            'first_name': 'Carlos',
            'last_name': 'Mendoza',
            'email': 'carlos@test.com',
            'password': 'password123',
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data.get('email'), 'carlos@test.com')

    def test_03_get_products_public(self):
        url = '/products'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Solo debe listar productos disponibles
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['nombre'], 'Picante de Cuy')

    def test_04_create_product_forbidden_for_client(self):
        self.client.force_authenticate(user=self.client_user)
        url = '/products'
        data = {'nombre': 'Trucha Frita', 'precio': 25.00, 'disponible': True}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_05_create_product_allowed_for_admin(self):
        self.client.force_authenticate(user=self.admin_user)
        url = '/products'
        data = {'nombre': 'Trucha Frita', 'precio': 25.00, 'disponible': True}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['nombre'], 'Trucha Frita')

    def test_06_create_order_client(self):
        self.client.force_authenticate(user=self.client_user)
        url = '/orders'
        data = {
            'items': [
                {'producto': self.product1.id, 'cantidad': 2}
            ]
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(float(response.data['total']), 70.00)
        self.assertEqual(response.data['estado'], 'pendiente')
        self.assertEqual(len(response.data['items']), 1)

    def test_07_order_mine_client(self):
        self.client.force_authenticate(user=self.client_user)
        # Crear orden
        order = Order.objects.create(cliente=self.client_user, total=35.00)
        url = '/orders/mine'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_08_admin_orders_list_and_status_update(self):
        # Crear orden de cliente
        order = Order.objects.create(cliente=self.client_user, total=35.00, estado='pendiente')

        # Cliente intenta ver admin orders (debe ser 403)
        self.client.force_authenticate(user=self.client_user)
        response_forbidden = self.client.get('/admin/orders')
        self.assertEqual(response_forbidden.status_code, status.HTTP_403_FORBIDDEN)

        # Admin consulta admin orders
        self.client.force_authenticate(user=self.admin_user)
        response_admin = self.client.get('/admin/orders')
        self.assertEqual(response_admin.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response_admin.data), 1)

        # Admin cambia estado
        patch_response = self.client.patch(
            f'/orders/{order.id}/status',
            {'estado': 'en preparacion'},
            format='json',
        )
        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.estado, 'en preparacion')
