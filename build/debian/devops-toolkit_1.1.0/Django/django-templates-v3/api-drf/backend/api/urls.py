"""
API URLs
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from . import views

# DRF Router
router = DefaultRouter()

app_name = 'api'

urlpatterns = [
    # API Root
    path('', views.api_root, name='api-root'),
    
    # Authentication
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Include router URLs
    path('', include(router.urls)),
    
    # Users
    path('users/', include('users.urls')),
]
