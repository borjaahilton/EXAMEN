from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (('Rol', {'fields': ('rol',)}),)
    add_fieldsets = UserAdmin.add_fieldsets + (('Datos de cuenta', {'fields': ('email', 'rol')}),)
    list_display = ('username', 'email', 'first_name', 'last_name', 'rol', 'is_staff')