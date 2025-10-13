from django.urls import path
from . import views
urlpatterns = [
    path('auth/signup/', views.signup),
    path('', views.index),
    path('classify/', views.ClassificationView.as_view()),
    path('discoveries/', views.DiscoveriesListView.as_view(), name='discoveries_list')
]