
# classifier/ml_inference.py
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
from pathlib import Path
import logging
import torch.nn.functional as F

logger = logging.getLogger(__name__)

class ImageClassifier:
    """A singleton class to load and run the PyTorch model."""
    
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ImageClassifier, cls).__new__(cls)
            cls._instance.model = None
            cls._instance.class_names = []
            cls._instance.preprocess = None
            cls._instance._load_model()
        return cls._instance

    def _load_model(self):
        """Internal method to load the model and class names."""
        try:
            base_dir = Path(__file__).resolve().parent.parent
            model_path = base_dir / 'models' / 'mobile_model.pth'
            classes_path = base_dir / 'models' / 'classes.txt'
            
            # Check if files exist
            if not model_path.exists():
                raise FileNotFoundError(f"Model file not found: {model_path}")
            if not classes_path.exists():
                raise FileNotFoundError(f"Classes file not found: {classes_path}")
            
            # Load class names
            with open(classes_path, 'r') as f:
                self.class_names = [line.strip() for line in f.readlines()]
            
            if not self.class_names:
                raise ValueError("No classes found in classes.txt")
            
            num_classes = len(self.class_names)
            logger.info(f"✅ Found {num_classes} classes: {self.class_names}")

            # Recreate the model structure
            self.model = models.mobilenet_v3_large(pretrained=False)
            num_ftrs = self.model.classifier[-1].in_features
            self.model.classifier[-1] = nn.Linear(num_ftrs, num_classes)
            
            # Load the trained weights and set to eval mode
            self.model.load_state_dict(
                torch.load(model_path, map_location=torch.device('cpu'), weights_only=True)
            )
            self.model.eval()
            logger.info("✅ PyTorch Model loaded and in eval mode.")

            # Define preprocessing transformations
            self.preprocess = transforms.Compose([
                transforms.Resize(256),
                transforms.CenterCrop(224),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406], 
                    std=[0.229, 0.224, 0.225]
                ),
            ])
            logger.info("✅ Image preprocessing pipeline initialized.")
            
        except FileNotFoundError as e:
            logger.error(f"❌ File error during model loading: {e}")
            raise
        except Exception as e:
            logger.error(f"❌ Error during model loading: {e}")
            raise

    # def predict(self, image_file):
    #     """
    #     Takes an uploaded image file, preprocesses it, and returns the prediction.
        
    #     Args:
    #         image_file: An uploaded image file object
            
    #     Returns:
    #         str: The predicted class name, or None if prediction fails
    #     """
    #     try:
    #         if not self.model or not self.preprocess:
    #             logger.error("Model not initialized")
    #             return None
            
    #         # Open and preprocess the image
    #         image_bytes = image_file.read()
            
    #         if not image_bytes:
    #             logger.error("Empty image file received")
    #             return None
            
    #         image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
            
    #         input_tensor = self.preprocess(image)
    #         input_batch = input_tensor.unsqueeze(0)

    #         # Run inference
    #         with torch.no_grad():
    #             output = self.model(input_batch)
    #             _, predicted_idx = torch.max(output, 1)
            
    #         predicted_class = self.class_names[predicted_idx.item()]
    #         logger.info(f"✅ Prediction: {predicted_class}")
    #         return predicted_class
            
    #     except Image.UnidentifiedImageError:
    #         logger.error("Invalid image file format")
    #         return None
    #     except Exception as e:
    #         logger.error(f"❌ Error during prediction: {e}")
    #         return None

    def predict(self, image_file, confidence_threshold=0.5):
        """
        Takes an uploaded image file, preprocesses it, and returns the prediction
        if the confidence is above a threshold.

        Args:
            image_file: An uploaded image file object.
            confidence_threshold (float): The minimum confidence for a prediction to be accepted.

        Returns:
            tuple: A tuple containing the predicted class name (str) and the confidence score (float),
                   or ("Unknown", confidence_score) if the confidence is below the threshold.
                   Returns (None, None) if prediction fails.
        """
        try:
            if not self.model or not self.preprocess:
                logger.error("Model not initialized")
                return None, None

            # Open and preprocess the image
            image_bytes = image_file.read()

            if not image_bytes:
                logger.error("Empty image file received")
                return None, None

            image = Image.open(io.BytesIO(image_bytes)).convert('RGB')

            input_tensor = self.preprocess(image)
            input_batch = input_tensor.unsqueeze(0)

            # Run inference
            with torch.no_grad():
                output = self.model(input_batch)

                # Get probabilities and the highest confidence score
                probabilities = F.softmax(output, dim=1)
                confidence, predicted_idx = torch.max(probabilities, 1)
                confidence_score = confidence.item()

            # Check if confidence is below the threshold
            if confidence_score < confidence_threshold:
                predicted_class = "Unknown"
                logger.info(f"🤔 Prediction confidence ({confidence_score:.2f}) is below the threshold ({confidence_threshold}). Returning 'Unknown'.")
            else:
                predicted_class = self.class_names[predicted_idx.item()]
                logger.info(f"✅ Prediction: {predicted_class} with confidence {confidence_score:.2f}")

            return predicted_class, confidence_score

        except Image.UnidentifiedImageError:
            logger.error("Invalid image file format")
            return None, None
        except Exception as e:
            logger.error(f"❌ Error during prediction: {e}")
            return None, None
# Instantiate the classifier once when the module is loaded
# This ensures the model is loaded into memory only once when the server starts.
try:
    classifier_instance = ImageClassifier()
except Exception as e:
    logger.error(f"Failed to initialize classifier: {e}")
    classifier_instance = None