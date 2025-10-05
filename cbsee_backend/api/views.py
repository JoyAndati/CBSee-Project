from django.shortcuts import render
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view

# Create your views here.
def signup(request):
    print('Signing up')
    return 

@api_view(['GET'])
def index(request):
    print('Take me thru dere');
    return Response({'message':'Take me through dere'}, status=status.HTTP_200_OK)