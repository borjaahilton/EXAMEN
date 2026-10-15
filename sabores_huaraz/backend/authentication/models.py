from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CHOICES = (
        ('admin', 'Administrador'),
        ('cliente', 'Cliente'),
    )

    email = models.EmailField(unique=True)
    rol = models.CharField(max_length=20, choices=ROLE_CHOICES, default='cliente')

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name']

    def __str__(self):
        return f'{self.email} ({self.rol})'