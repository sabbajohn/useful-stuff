from django.shortcuts import render


def index(request):
    """Serve the frontend SPA"""
    return render(request, 'frontend/index.html')
