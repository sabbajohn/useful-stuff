"""
API Views
"""
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.reverse import reverse


@api_view(['GET'])
def api_root(request, format=None):
    """
    API Root - Welcome to ProjTest API
    """
    return Response({
        'message': 'Welcome to ProjTest API',
        'version': '1.0.0',
        'endpoints': {
            'auth': {
                'token': reverse('api:token_obtain_pair', request=request, format=format),
                'refresh': reverse('api:token_refresh', request=request, format=format),
            },
            'users': reverse('api:users:user-list', request=request, format=format),
            'documentation': {
                'swagger': reverse('swagger-ui', request=request, format=format),
                'redoc': reverse('redoc', request=request, format=format),
            }
        }
    })
