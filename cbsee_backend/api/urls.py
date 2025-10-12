from django.urls import path
from . import views
urlpatterns = [
    path('auth/signup/', views.signup),
    path('', views.index),
    path('classify/', views.ClassificationView.as_view())
]