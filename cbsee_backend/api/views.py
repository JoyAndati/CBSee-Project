
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
import json
from django.shortcuts import render
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view
from firebase_admin import auth
from .models import Teacher, Student, ObjectRecognized, Object
from django.core.serializers import serialize
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
from .serializers import ImageUploadSerializer
from .ml_inference import classifier_instance
from .models import ObjectRecognized
from .serializers import DiscoverySerializer
from rest_framework.generics import ListAPIView

@api_view(['GET'])
def index(request):
    print('Take me thru dere');
    return Response({'message':'Take me through dere'}, status=status.HTTP_200_OK)


# classifier/views.py

class ClassificationView(APIView):
    """
    An APIView for handling image classification.
    """
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        """
        Handles the POST request with an uploaded image.
        """
        try:
            token = request.data.get('body')
            data = json.loads(token)
            token = data.get('token');
             # Verify Firebase ID token
            uid=''
            if token:
                # print(f"token present:{token}")
                decoded = auth.verify_id_token(token)
                uid = decoded.get('uid')
            else:
                uid = 'Hn7MEsRYmtgReAvbEpKpT3VJdxf1'
            serializer = ImageUploadSerializer(data=request.data)
            if serializer.is_valid():
                # Get the validated image file
                image = serializer.validated_data['image']
                
                # Get prediction from our ML service
                prediction = classifier_instance.predict(image)
                print(prediction)
                student = Student.objects.get(StudentID=uid)
                if prediction:
                    # get the object
                    obj = Object.objects.get(ObjectName=prediction)
                    objRecognized = ObjectRecognized.objects.create(Student=student, Object=obj)

                    return Response(
                        {'prediction': prediction, 'description':obj.ObjectDescription}, 
                        status=status.HTTP_200_OK
                    )
                else:
                    return Response(
                        {'error': 'Failed to process the image. Please try again.'}, 
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
            else:
                # Return validation errors if the data is invalid (e.g., no image)
                return Response(
                    {'error': 'Invalid request. Please provide an image file.', 'details': serializer.errors}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        except Exception as e:
            print(e);
            return Response(
                {'error': f'Server error: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )



class DiscoveriesListView(ListAPIView):
    """
    Provides a list of all objects discovered by the currently authenticated student.
    """
    serializer_class = DiscoverySerializer


    def get_queryset(self):
        request = self.request
        token = request.headers.get('Authorization')

        uid = None
        if token:
            try:
                # Extract token after "Bearer "
                id_token = token.split(' ')[-1]
                decoded = auth.verify_id_token(id_token)
                uid = decoded.get('uid')
            except Exception as e:
                print(f"Token verification failed: {e}")
                return ObjectRecognized.objects.none()

        if not uid:
            return ObjectRecognized.objects.none()

        try:
            student = Student.objects.get(StudentID=uid)
        except Student.DoesNotExist:
            return ObjectRecognized.objects.none()

        # Filter recognized objects for this student
        return (
            ObjectRecognized.objects
            .filter(Student=student)
            .select_related('Object')
            .order_by('-Timestamp')
        )

@api_view(['POST'])
def add_student(request):
    try:
        token = request.headers.get('Authorization')
        

        if not token:
            return Response({'message': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)
        token = token.split(" ")[-1]
        
        decoded = auth.verify_id_token(token.strip())
        if not decoded:
            raise Exception('Bad token')

        teacher_uid = decoded.get('uid')
        teacher = Teacher.objects.get(TeacherID=teacher_uid)
        
        student_email = request.data.get('email')
        # Here you would typically have a way to identify the student by email.
        # This is a simplified example. You might need a more complex lookup.
        student = Student.objects.get(Email=student_email)
        
        student.Teacher = teacher
        student.save()

        return Response({'message': 'Student added successfully'}, status=status.HTTP_201_CREATED)
    
    except Student.DoesNotExist:
        return Response({'message': 'Student not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"[ERROR]:{e}")
        return Response({'message': f'[ERROR]: {e}'}, status=status.HTTP_400_BAD_REQUEST)

# --- Helper Function for Authentication ---
# This function centralizes token verification to keep your code DRY (Don't Repeat Yourself)
def verify_firebase_token(request):
    """
    Verifies the Firebase token from the Authorization header.
    Returns the decoded token dictionary or None if invalid.
    """
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
    
    id_token = auth_header.split('Bearer ').pop()
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        print(f"Token verification failed: {e}")
        return None

# --- Updated and New Views ---

@api_view(['GET'])
def check_profile(request):
    """
    Checks if a user profile (Student or Teacher) exists for the given Firebase UID.
    The Flutter app should call this immediately after a successful login.
    """
    decoded_token = verify_firebase_token(request)
    if not decoded_token:
        return Response({'message': 'Invalid or missing token'}, status=status.HTTP_401_UNAUTHORIZED)
    
    uid = decoded_token.get('uid')
    
    # Check if a Teacher profile exists
    if Teacher.objects.filter(TeacherID=uid).exists():
        return Response({'profileExists': True, 'userType': 'teacher'}, status=status.HTTP_200_OK)
    
    # Check if a Student profile exists
    if Student.objects.filter(StudentID=uid).exists():
        return Response({'profileExists': True, 'userType': 'student'}, status=status.HTTP_200_OK)
        
    # If no profile is found
    return Response({'profileExists': False}, status=status.HTTP_200_OK)


@api_view(['POST'])
def signup(request):
    """
    Creates a Student or Teacher profile in the database.
    This should be called when a new user provides their role and other details.
    """
    data = request.data

    try:
        token = data.get('token')
        if not token:
            return Response({'message': 'Missing token'}, status=status.HTTP_400_BAD_REQUEST)

        decoded = auth.verify_id_token(token)
        uid = decoded.get('uid')
        email = decoded.get('email')
        
        # Prefer the name from the request, fallback to the token's display name
        name = data.get('name', decoded.get('name', 'Unknown User'))
        user_type = data.get('type')
        grade = data.get('gradeLevel')

        if user_type == 'student':
            # This logic is fine, it creates a student record linked to the Firebase UID.
            student, created = Student.objects.get_or_create(
                StudentID=uid,
                defaults={'Name': name, 'GradeLevel': grade, 'Email': email}
            )
            if not created:
                return Response({'message': 'Student already exists'}, status=status.HTTP_200_OK)
            return Response({'message': 'Student account created'}, status=status.HTTP_201_CREATED)

        elif user_type == 'teacher':
            # This logic is fine, it creates a teacher record.
            teacher, created = Teacher.objects.get_or_create(
                TeacherID=uid,
                defaults={
                    'Name': name,
                    'Email': email,
                    'School': data.get('school'),
                    'ContactInfo': data.get('contactInfo', email),
                    'Subject': data.get('subject'),
                    'GradeLevel': grade
                }
            )
            if not created:
                return Response({'message': 'Teacher already exists'}, status=status.HTTP_200_OK)
            return Response({'message': 'Teacher account created'}, status=status.HTTP_201_CREATED)

        else:
            return Response({'message': 'Invalid user type'}, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        print(f"Signup error: {e}")
        return Response({'message': 'An error occurred during signup', 'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

# --- Your Existing Views (Refactored for Authentication) ---

@api_view(['GET'])
def dashboard(request):
    decoded_token = verify_firebase_token(request)
    if not decoded_token:
        return Response({'message': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)
        
    try:
        uid = decoded_token.get('uid')
        teacher = Teacher.objects.get(TeacherID=uid)
        students = Student.objects.filter(Teacher=teacher)

        # Your serialization logic is fine
        students_data = json.loads(serialize('json', students))
        student_list = [
            {'StudentID': item['pk'], 'Name': item['fields']['Name'], 'GradeLevel': item['fields']['GradeLevel']}
            for item in students_data
        ]
        return Response({'students': student_list, 'name': teacher.Name}, status=status.HTTP_200_OK)
    except Teacher.DoesNotExist:
        return Response({'message': 'Teacher profile not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'message': f'[ERROR]: {e}'}, status=status.HTTP_400_BAD_REQUEST)