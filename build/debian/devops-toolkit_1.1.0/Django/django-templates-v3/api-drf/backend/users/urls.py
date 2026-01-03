"""
User URLs
"""
from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    path('', views.UserListCreateView.as_view(), name='user-list'),
    path('<int:pk>/', views.UserDetailView.as_view(), name='user-detail'),
    path('me/', views.user_profile, name='user-profile'),
]
