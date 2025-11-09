from django.urls import path
from . import views
urlpatterns = [
    path('auth/signup/', views.signup),
    path('auth/check_profile/', views.check_profile),
    path('', views.index),
    path('classify/', views.ClassificationView.as_view()),
    path('discoveries/', views.DiscoveriesListView.as_view(), name='discoveries_list'),
    path('dashboard/', views.dashboard, name='teacher-dashboard'),
    path('add_student/', views.add_student, name='add-student'),
]