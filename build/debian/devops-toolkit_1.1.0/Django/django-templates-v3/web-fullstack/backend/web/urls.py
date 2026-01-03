"""
Web URLs
"""
from django.urls import path
from django.contrib.auth import views as auth_views
from . import views

app_name = 'web'

urlpatterns = [
    # Web pages
    path('', views.home, name='home'),
    path('about/', views.about, name='about'),
    path('dashboard/', views.dashboard, name='dashboard'),
    
    # Authentication
    path('login/', auth_views.LoginView.as_view(template_name='web/login.html'), name='login'),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),
]
