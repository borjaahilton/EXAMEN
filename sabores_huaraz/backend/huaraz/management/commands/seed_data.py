from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from huaraz.models import Order, OrderItem, Product


User = get_user_model()


class Command(BaseCommand):
    help = 'Puebla la base de datos con usuarios y platos tipicos de Huaraz de prueba'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Iniciando carga de datos iniciales...'))

        # 1. Crear Administrador
        admin_email = 'admin@sabores.com'
        admin_user, created_admin = User.objects.get_or_create(
            email=admin_email,
            defaults={
                'username': admin_email,
                'first_name': 'Administrador',
                'last_name': 'Sabores',
                'rol': 'admin',
                'is_staff': True,
                'is_superuser': True,
            },
        )
        if created_admin:
            admin_user.set_password('123')
            admin_user.save()
            self.stdout.write(self.style.SUCCESS(f'Admin creado: {admin_email} (password: 123)'))
        else:
            admin_user.rol = 'admin'
            admin_user.set_password('123')
            admin_user.save()
            self.stdout.write(self.style.WARNING(f'Admin ya existia, actualizado: {admin_email}'))

        # 2. Crear Cliente
        cliente_email = 'cliente@sabores.com'
        cliente_user, created_client = User.objects.get_or_create(
            email=cliente_email,
            defaults={
                'username': cliente_email,
                'first_name': 'Juan',
                'last_name': 'Perez',
                'rol': 'cliente',
            },
        )
        if created_client:
            cliente_user.set_password('123')
            cliente_user.save()
            self.stdout.write(self.style.SUCCESS(f'Cliente creado: {cliente_email} (password: 123)'))
        else:
            cliente_user.rol = 'cliente'
            cliente_user.set_password('123')
            cliente_user.save()
            self.stdout.write(self.style.WARNING(f'Cliente ya existia, actualizado: {cliente_email}'))

        # 3. Platos Típicos de Huaraz
        platos = [
            {
                'nombre': 'Picante de Cuy',
                'descripcion': 'Cuy dorado crocante acompañado de papas sancochadas y salsa de aji panca huaracino.',
                'precio': 35.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
            },
            {
                'nombre': 'Llunca Cashqui de Gallina',
                'descripcion': 'Sopa tradicional ancashina a base de trigo resbalado y gallina de corral aromatizada con hierbabuena.',
                'precio': 18.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80',
            },
            {
                'nombre': 'Cuchi Canca',
                'descripcion': 'Lechón tierno horneado y macerado con aji mirasol, chicha de jora y hierbas andinas.',
                'precio': 28.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
            },
            {
                'nombre': 'Trucha Frita Andina',
                'descripcion': 'Trucha fresca del rio Santa dorada al ajo, servida con yucas, papas doradas y sarsa criolla.',
                'precio': 25.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80',
            },
            {
                'nombre': 'Ceviche de Chocho (Tarwi)',
                'descripcion': 'Entrada refrescante y nutritiva a base de semillas de chocho con cebolla, culantro, limon y aji rocoto.',
                'precio': 12.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1535400255456-984241443b29?auto=format&fit=crop&w=800&q=80',
            },
            {
                'nombre': 'Pachamanca Ancashina',
                'descripcion': 'Cerdo, pollo y carnero cocidos con hierbas andinas (chincho, huacatay), habas, papas y humitas.',
                'precio': 40.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
            },
            {
                'nombre': 'Chicha de Jora Huaracina',
                'descripcion': 'Bebida fermentada de maiz jora con canela y clavo, receta centenaria de la Cordillera Blanca.',
                'precio': 6.00,
                'disponible': True,
                'imagen_url': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
            },
        ]

        for p_data in platos:
            prod, created_prod = Product.objects.update_or_create(
                nombre=p_data['nombre'],
                defaults=p_data,
            )
            accion = 'Creado' if created_prod else 'Actualizado'
            self.stdout.write(f' - [{accion}] {prod.nombre} - S/ {prod.precio}')

        # 4. Crear un pedido de ejemplo si no existe ninguno
        if not Order.objects.exists():
            cuy = Product.objects.filter(nombre='Picante de Cuy').first()
            chicha = Product.objects.filter(nombre='Chicha de Jora Huaracina').first()
            if cuy and chicha:
                order = Order.objects.create(
                    cliente=cliente_user,
                    estado='pendiente',
                    total=(cuy.precio * 1) + (chicha.precio * 2),
                )
                OrderItem.objects.create(
                    pedido=order,
                    producto=cuy,
                    cantidad=1,
                    precio_unitario=cuy.precio,
                    subtotal=cuy.precio * 1,
                )
                OrderItem.objects.create(
                    pedido=order,
                    producto=chicha,
                    cantidad=2,
                    precio_unitario=chicha.precio,
                    subtotal=chicha.precio * 2,
                )
                self.stdout.write(self.style.SUCCESS(f'Pedido de prueba #{order.id} creado para {cliente_email}'))

        self.stdout.write(self.style.SUCCESS('\n¡Datos iniciales cargados exitosamente!'))
