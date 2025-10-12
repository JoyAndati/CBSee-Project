# convert_model.py
import torch
import torch.nn as nn
from torchvision import models
import argparse
import os

def convert_model_to_lite(checkpoint_path, num_classes, save_name):
    """
    Loads a model state_dict, and converts it to a TorchScript Lite model.
    """
    # --- 1. Load Model Architecture ---
    print("🧠 Loading pre-trained MobileNetV3 model structure...")
    # We must recreate the same model structure as during training
    model = models.mobilenet_v3_small(pretrained=False) # Not pre-trained, we'll load our own weights

    # Get the number of input features for the classifier
    num_ftrs = model.classifier[-1].in_features

    # Replace the final layer to match the number of classes in our trained model
    model.classifier[-1] = nn.Linear(num_ftrs, num_classes)
    print(f"✅ Model structure created for {num_classes} classes.")

    # --- 2. Load Trained Weights ---
    print(f"💾 Loading trained weights from '{checkpoint_path}'...")
    # Load the state dictionary
    state_dict = torch.load(checkpoint_path, map_location=torch.device('cpu'))
    model.load_state_dict(state_dict)
    print("✅ Weights loaded successfully.")

    # --- 3. Convert to TorchScript ---
    print("🔧 Converting model to TorchScript...")
    # Set the model to evaluation mode. This is crucial for consistent results.
    model.eval()

    # Create a dummy input tensor with the correct shape (batch_size, channels, height, width)
    # This is what the model expects from our Flutter app later.
    example_input = torch.rand(1, 3, 224, 224)

    # Trace the model. This records the operations executed on the dummy input.
    traced_script_module = torch.jit.trace(model, example_input)
    print("✅ Model traced.")

    # --- 4. Optimize and Save for Mobile (Lite Interpreter) ---
    print("⚡ Optimizing for mobile and saving as .ptl file...")
    from torch.utils.mobile_optimizer import optimize_for_mobile
    optimized_traced_module = optimize_for_mobile(traced_script_module)

    # Save the optimized model
    optimized_traced_module._save_for_lite_interpreter(save_name)
    print(f"🎉 Success! Model saved to '{save_name}'")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Convert PyTorch model to TorchScript Lite format.")
    parser.add_argument("--checkpoint", type=str, required=True,
                        help="Path to the trained model .pth state_dict file.")
    parser.add_argument("--num-classes", type=int, required=True,
                        help="Number of output classes for your model.")
    parser.add_argument("--output-name", type=str, default="mobile_image_classifier.ptl",
                        help="Name for the output .ptl file.")

    args = parser.parse_args()

    if not os.path.exists(args.checkpoint):
        print(f"❌ Error: Checkpoint file not found at '{args.checkpoint}'")
    else:
        convert_model_to_lite(args.checkpoint, args.num_classes, args.output_name)