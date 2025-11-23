from rest_framework import serializers
from .models import Object, ObjectRecognized

class ImageUploadSerializer(serializers.Serializer):
    image = serializers.ImageField(required=True)

class DiscoverySerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source='ID')
    name = serializers.CharField(source='Object.ObjectName')
    category = serializers.CharField(source='Object.ObjectCategory')
    discoveredDate = serializers.DateTimeField(source='Timestamp')
    
    # We don't have images in DB yet, but we can send an empty field 
    # or handle it in Frontend (which we did in DiscoveryItem.fromJson)
    imageUrl = serializers.SerializerMethodField()

    class Meta:
        model = ObjectRecognized
        fields = ('id', 'name', 'category', 'discoveredDate', 'imageUrl')

    def get_imageUrl(self, obj):
        return ""