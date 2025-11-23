import json
from django.utils import timezone
from datetime import timedelta
from django.db.models import Count
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view
from firebase_admin import auth
from .models import Teacher, Student, ObjectRecognized, Object
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from .serializers import ImageUploadSerializer, DiscoverySerializer
from .ml_inference import classifier_instance
from rest_framework.generics import ListAPIView

# --- Helper ---
def verify_firebase_token(request):
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
    try:
        return auth.verify_id_token(auth_header.split('Bearer ').pop())
    except Exception as e:
        print(f"Token verification failed: {e}")
        return None

@api_view(['GET'])
def index(request):
    return Response({'message':'API is running'}, status=status.HTTP_200_OK)

class ClassificationView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    def post(self, request, *args, **kwargs):
        try:
            token_str = request.data.get('body')
            uid = ''
            if token_str:
                data = json.loads(token_str)
                token = data.get('token')
                if token:
                    try:
                        decoded = auth.verify_id_token(token)
                        uid = decoded.get('uid')
                    except: pass
            
            serializer = ImageUploadSerializer(data=request.data)
            if serializer.is_valid():
                image = serializer.validated_data['image']
                prediction, conf = classifier_instance.predict(image)
                
                if prediction and prediction != "Unknown":
                    obj, _ = Object.objects.get_or_create(
                        ObjectName=prediction,
                        defaults={'ObjectDescription': f'This is a {prediction}.', 'ObjectCategory': 'General'}
                    )
                    if uid:
                        try:
                            student = Student.objects.get(StudentID=uid)
                            ObjectRecognized.objects.create(Student=student, Object=obj)
                        except Student.DoesNotExist:
                            pass 
                    return Response({'prediction': prediction, 'description': obj.ObjectDescription}, status=status.HTTP_200_OK)
                else:
                    return Response({'prediction': 'Unknown', 'description': 'Try adding more light.'}, status=status.HTTP_200_OK)
            return Response({'error': 'Invalid request.'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DiscoveriesListView(ListAPIView):
    serializer_class = DiscoverySerializer
    def get_queryset(self):
        decoded = verify_firebase_token(self.request)
        if not decoded: return ObjectRecognized.objects.none()
        uid = decoded.get('uid')
        try:
            student = Student.objects.get(StudentID=uid)
            return ObjectRecognized.objects.filter(Student=student).select_related('Object').order_by('-Timestamp')
        except Student.DoesNotExist: return ObjectRecognized.objects.none()

@api_view(['GET'])
def check_profile(request):
    decoded_token = verify_firebase_token(request)
    if not decoded_token: return Response({'message': 'Invalid token'}, status=status.HTTP_401_UNAUTHORIZED)
    uid = decoded_token.get('uid')
    if Teacher.objects.filter(TeacherID=uid).exists(): return Response({'profileExists': True, 'userType': 'teacher'}, status=status.HTTP_200_OK)
    if Student.objects.filter(StudentID=uid).exists(): return Response({'profileExists': True, 'userType': 'student'}, status=status.HTTP_200_OK)
    return Response({'profileExists': False}, status=status.HTTP_200_OK)

@api_view(['POST'])
def signup(request):
    data = request.data
    token = data.get('token')
    if not token: decoded = verify_firebase_token(request)
    else:
        try: decoded = auth.verify_id_token(token)
        except: decoded = None
    if not decoded: return Response({'message': 'Invalid Token'}, status=status.HTTP_401_UNAUTHORIZED)
    uid = decoded.get('uid')
    email = decoded.get('email')
    name = data.get('name', decoded.get('name', 'User'))
    user_type = data.get('type')
    grade = data.get('gradeLevel', 'Grade 1')
    try:
        if user_type == 'student':
            Student.objects.update_or_create(StudentID=uid, defaults={'Name': name, 'GradeLevel': grade, 'Email': email})
            return Response({'message': 'Student account created'}, status=status.HTTP_201_CREATED)
        elif user_type == 'teacher':
            Teacher.objects.update_or_create(TeacherID=uid, defaults={'Name': name, 'Email': email, 'School': data.get('school', ''), 'ContactInfo': email, 'Subject': data.get('subject', 'General'), 'GradeLevel': grade})
            return Response({'message': 'Teacher account created'}, status=status.HTTP_201_CREATED)
        else: return Response({'message': 'Invalid user type'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e: return Response({'message': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def dashboard(request):
    decoded_token = verify_firebase_token(request)
    if not decoded_token: return Response({'message': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)
    try:
        uid = decoded_token.get('uid')
        teacher = Teacher.objects.get(TeacherID=uid)
        students = Student.objects.filter(Teacher=teacher)
        student_list = []
        today = timezone.now().date()
        for student in students:
            objects_today = ObjectRecognized.objects.filter(Student=student, Timestamp__date=today).count()
            last_rec = ObjectRecognized.objects.filter(Student=student).order_by('-Timestamp').first()
            last_active_str = "Never"
            if last_rec and last_rec.Timestamp:
                diff = timezone.now() - last_rec.Timestamp
                if diff.days == 0: last_active_str = "Today"
                elif diff.days == 1: last_active_str = "Yesterday"
                else: last_active_str = f"{diff.days} days ago"
            student_list.append({'StudentID': student.StudentID, 'Name': student.Name, 'GradeLevel': student.GradeLevel, 'objectsFound': objects_today, 'lastActive': last_active_str})
        return Response({'students': student_list, 'name': teacher.Name}, status=status.HTTP_200_OK)
    except Teacher.DoesNotExist: return Response({'message': 'Teacher profile not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
def add_student(request):
    decoded = verify_firebase_token(request)
    if not decoded: return Response({'message': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)
    try:
        teacher_uid = decoded.get('uid')
        teacher = Teacher.objects.get(TeacherID=teacher_uid)
        student_email = request.data.get('email')
        student = Student.objects.get(Email=student_email)
        student.Teacher = teacher
        student.save()
        return Response({'message': 'Student added'}, status=status.HTTP_201_CREATED)
    except Exception as e: return Response({'message': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def student_stats(request, student_id):
    decoded = verify_firebase_token(request)
    if not decoded:
        return Response({'message': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)
        
    try:
        student = Student.objects.get(StudentID=student_id)
        
        # 1. Total Discoveries
        total_count = ObjectRecognized.objects.filter(Student=student).count()
        
        # 2. Objects this week
        one_week_ago = timezone.now() - timedelta(days=7)
        week_count = ObjectRecognized.objects.filter(
            Student=student, 
            Timestamp__gte=one_week_ago
        ).count()

        # 3. Category Stats (for the chart)
        category_counts = ObjectRecognized.objects.filter(Student=student)\
            .values('Object__ObjectCategory')\
            .annotate(count=Count('ID'))
            
        chart_data = {}
        most_found_cat = "None"
        max_cat_count = 0
        
        for entry in category_counts:
            cat = entry['Object__ObjectCategory'] or "General"
            count = entry['count']
            if total_count > 0:
                chart_data[cat] = count / total_count 
            else:
                chart_data[cat] = 0.0
            
            if count > max_cat_count:
                max_cat_count = count
                most_found_cat = cat

        # 4. Recent History (Top 5)
        discoveries = ObjectRecognized.objects.filter(Student=student).select_related('Object').order_by('-Timestamp')[:5]
        serializer = DiscoverySerializer(discoveries, many=True)
        
        return Response({
            'student_name': student.Name,
            'total_discoveries': total_count,
            'weekly_discoveries': week_count,
            'most_found_category': most_found_cat,
            'chart_data': chart_data,
            'history': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Student.DoesNotExist:
        return Response({'message': 'Student not found'}, status=status.HTTP_404_NOT_FOUND)