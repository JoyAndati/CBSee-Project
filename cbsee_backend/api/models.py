from django.db import models

# Create your models here.
class Teacher(models.Model):
    TeacherID = models.CharField(max_length=50, primary_key=True)
    Name = models.CharField(max_length=100)
    Email = models.EmailField(unique=True)
    School = models.CharField(max_length=100)
    ContactInfo = models.CharField(max_length=100)

    def __str__(self):
        return self.Name


class Student(models.Model):
    StudentID = models.CharField(max_length=50, primary_key=True)
    Name = models.CharField(max_length=100)
    DateOfBirth = models.DateTimeField(auto_now_add=True)
    GradeLevel = models.CharField(max_length=50)
    Teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name='students')

    def __str__(self):
        return self.Name


class Parent(models.Model):
    ParentID = models.CharField(max_length=50, primary_key=True)
    Name = models.CharField(max_length=100)
    Email = models.EmailField(unique=True)
    ContactInfo = models.CharField(max_length=100)

    def __str__(self):
        return self.Name


class ProgressReport(models.Model):
    ReportID = models.AutoField(primary_key=True)
    Student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='progress_reports')
    DateGenerated = models.DateTimeField(auto_now_add=True)
    Summary = models.CharField(max_length=255)
    Recommendations = models.CharField(max_length=255)

    def __str__(self):
        return f"Report {self.ReportID} for {self.Student.Name}"

class Object(models.Model):
    ObjectID = models.AutoField(primary_key=True);
    ObjectName = models.CharField(max_length=100)
    ObjectDescription = models.CharField(max_length=255)
    ObjectCategory = models.CharField(max_length=255, null=True)
    class Meta:
        verbose_name = "Object"
        verbose_name_plural = "Objects"
    def __str__(self):
        return self.ObjectName

class ObjectRecognized(models.Model):
    ID = models.AutoField(primary_key=True)
    Student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='recognized_objects')
    Object = models.ForeignKey(Object, on_delete=models.SET_NULL, null=True, related_name='recognized_instances')
    Timestamp = models.DateTimeField(auto_now_add=True, help_text="The date and time this object was recognized.", null=True)

    def __str__(self):
        return f"{self.Object.ObjectName} -- {self.Student.Name}"
