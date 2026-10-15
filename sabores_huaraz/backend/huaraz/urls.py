from django.urls import include, path

urlpatterns = [
    path('', include('huaraz.api.urls')),
]