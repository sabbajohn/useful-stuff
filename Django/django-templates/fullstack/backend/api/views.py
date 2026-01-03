from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import JsonResponse


@api_view(['GET'])
def health_check(request):
    """Health check endpoint"""
    return Response({
        'status': 'healthy',
        'message': 'ProjTest API is running!'
    })


# class ItemViewSet(viewsets.ModelViewSet):
#     """Example ViewSet - replace with your models"""
#     pass
