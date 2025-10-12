# classifier/serializers.py
from rest_framework import serializers

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