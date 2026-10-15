from rest_framework import permissions


class IsAdminUserRole(permissions.BasePermission):
    """Permite el acceso exclusivamente a usuarios con rol 'admin'."""
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.rol == 'admin'
        )


class IsAdminOrReadOnly(permissions.BasePermission):
    """Cualquiera puede consultar (GET), pero solo admin puede crear/modificar."""
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.rol == 'admin'
        )
