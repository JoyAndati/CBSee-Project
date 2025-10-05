from django.shortcuts import render
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view
from firebase_admin import auth
from .models import Teacher, Student
# Create your views here.

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
        name = decoded.get('name', 'Unknown User')

        # Handle user type
        if user_type == 'student':
            grade = data.get('gradeLevel')
            teacher_id = data.get('teacherId')

            # Make sure the teacher exists
            try:
                teacher = Teacher.objects.get(TeacherID=teacher_id)
            except Teacher.DoesNotExist:
                return Response({'message': 'Teacher not found'}, status=status.HTTP_404_NOT_FOUND)

            # Create student (if not already exists)
            student, created = Student.objects.get_or_create(
                StudentID=uid,
                defaults={
                    'Name': name,
                    'GradeLevel': grade,
                    'Teacher': teacher
                }
            )

            if not created:
                return Response({'message': 'Student already exists'}, status=status.HTTP_200_OK)

            return Response({'message': 'Student account created'}, status=status.HTTP_201_CREATED)

        elif user_type == 'teacher':
            school = data.get('school')
            contact = data.get('contactInfo')

            teacher, created = Teacher.objects.get_or_create(
                TeacherID=uid,
                defaults={
                    'Name': name,
                    'Email': email,
                    'School': school,
                    'ContactInfo': contact
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