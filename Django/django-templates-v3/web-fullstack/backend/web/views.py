"""
Web views (Django templates)
"""
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model

User = get_user_model()


def home(request):
    """
    Home page
    """
    context = {
        'title': 'Home',
        'message': 'Bem-vindo ao ProjTest!'
    }
    return render(request, 'web/home.html', context)


def about(request):
    """
    About page
    """
    context = {
        'title': 'Sobre',
        'message': 'Esta é uma aplicação Django Fullstack'
    }
    return render(request, 'web/about.html', context)


@login_required
def dashboard(request):
    """
    Dashboard (requires login)
    """
    context = {
        'title': 'Dashboard',
        'user': request.user,
        'total_users': User.objects.count()
    }
    return render(request, 'web/dashboard.html', context)
