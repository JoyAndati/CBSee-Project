# classifier/serializers.py
from rest_framework import serializers
from .models import Object, ObjectRecognized

class ImageUploadSerializer(serializers.Serializer):
    """
    Serializer for the image upload. It validates that the 'image' field is present
    and is a valid image file. Matches the field name sent by the Flutter app.
    """
    image = serializers.ImageField(required=True, allow_empty_file=False)
    
    def validate_image(self, value):
        """
        Additional validation for the image field.
        """
        if not value:
            raise serializers.ValidationError("Image file is required and cannot be empty.")
        return value

class DiscoverySerializer(serializers.ModelSerializer):
    """
    Formats the recognized object data for the 'My Discoveries' screen.
    It renames fields to match what the Flutter DiscoveryItem model expects.
    """
    id = serializers.IntegerField(source='ID')
    name = serializers.CharField(source='Object.ObjectName')
    category = serializers.CharField(source='Object.ObjectCategory')
    discoveredDate = serializers.DateTimeField(source='Timestamp')

    class Meta:
        model = ObjectRecognized
        fields = ('id', 'name', 'category', 'discoveredDate')