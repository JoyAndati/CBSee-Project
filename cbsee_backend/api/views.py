
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

@api_view(['POST'])
def signup(request):
    data = request.data

    try:
        token = data.get('token')
        user_type = data.get('type')  # "student" or "teacher"

        if not token:
            return Response({'message': 'Missing token'}, status=status.HTTP_400_BAD_REQUEST)

        # Verify Firebase ID token
        decoded = auth.verify_id_token(token)
        uid = decoded.get('uid')
        email = decoded.get('email')
        name = decoded.get('display_name', 'Unknown User')
        if name=='Unknown User':
            name = data.get('name', 'unkown')
        # Handle user type
        grade = data.get('gradeLevel')
        if user_type == 'student':
            # teacher_id = data.get('teacherId')

            # # Make sure the teacher exists
            # try:
            #     teacher = Teacher.objects.get(TeacherID=teacher_id)
            # except Teacher.DoesNotExist:
            #     # return Response({'message': 'Teacher not found'}, status=status.HTTP_404_NOT_FOUND)
            #     print("Teacher does not exist")

            # Create student (if not already exists)
            student, created = Student.objects.get_or_create(
                StudentID=uid,
                defaults={
                    'Name': name,
                    'GradeLevel': grade,
                    'Teacher': None,
                    'Email':email
                }
            )

            if not created:
                return Response({'message': 'Student already exists'}, status=status.HTTP_200_OK)

            return Response({'message': 'Student account created'}, status=status.HTTP_201_CREATED)

        elif user_type == 'teacher':
            school = data.get('school')
            contact = data.get('contactInfo', 'example@example.com')
            subject = data.get('subject', 'Science')

            teacher, created = Teacher.objects.get_or_create(
                TeacherID=uid,
                defaults={
                    'Name': name,
                    'Email': email,
                    'School': school,
                    'ContactInfo': contact,
                    'Subject':subject,
                    'GradeLevel':grade
                }
            )

            if not created:
                return Response({'message': 'Teacher already exists'}, status=status.HTTP_200_OK)

            return Response({'message': 'Teacher account created'}, status=status.HTTP_201_CREATED)

        else:
            return Response({'message': 'Invalid user type'}, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        print("Signup error:", e)
        return Response({'message': 'Invalid or expired token', 'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def index(request):
    print('Take me thru dere');
    return Response({'message':'Take me through dere'}, status=status.HTTP_200_OK)


# classifier/views.py

# classifier/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
from .serializers import ImageUploadSerializer
from .ml_inference import classifier_instance
from .models import ObjectRecognized
from .serializers import DiscoverySerializer
from rest_framework.generics import ListAPIView

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



@api_view(['GET'])
def dashboard(request):
    try:
        token = request.headers.get('Authorization').split(" ")[-1]
        if not token:
            return Response({'message': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

        decoded = auth.verify_id_token(token)
        if not decoded:
            raise Exception('Bad token')

        uid = decoded.get('uid')
        teacher = Teacher.objects.get(TeacherID=uid)
        students = Student.objects.filter(Teacher=teacher)

        # Serialize the students' data
        students_data = json.loads(serialize('json', students))
        student_list = [
            {
                'StudentID': item['pk'],
                'Name': item['fields']['Name'],
                'GradeLevel': item['fields']['GradeLevel']
            }
            for item in students_data
        ]

        return Response({'students': student_list, 'name':teacher.Name}, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'message': f'[ERROR]: {e}'}, status=status.HTTP_400_BAD_REQUEST)

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