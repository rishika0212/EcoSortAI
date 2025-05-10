import cv2
import numpy as np
import tensorflow as tf
from pathlib import Path
import traceback
import os


# Supported labels
LABELS = ['HDPE', 'LDPE', 'PET', 'PP', 'PS']
IMG_SIZE = 224

# Label metadata for display in UI
LABEL_INFO = {
    "HDPE": {
        "found_in": "Milk jugs, shampoo bottles, cleaning containers",
        "recyclable": True,
        "what_to_do": "Rinse and recycle in your bin.",
        "impact": "Can be reused in park benches, pipes, etc."
    },
    "LDPE": {
        "found_in": "Grocery bags, bread bags, squeeze bottles",
        "recyclable": "Check locally",
        "what_to_do": "Drop off at store recycling bins.",
        "impact": "Prevents ocean litter when recycled properly."
    },
    "PET": {
        "found_in": "Water bottles, soda bottles, food containers",
        "recyclable": True,
        "what_to_do": "Rinse, remove cap, and recycle.",
        "impact": "Turns into t-shirts, backpacks, and more."
    },
    "PP": {
        "found_in": "Yogurt cups, straws, medicine bottles",
        "recyclable": "Check locally",
        "what_to_do": "Rinse and check with your recycler.",
        "impact": "Sturdy plastic, can be reused in storage bins, etc."
    },
    "PS": {
        "found_in": "Foam takeout boxes, packing peanuts, disposable cups",
        "recyclable": False,
        "what_to_do": "Avoid or use special drop-off if available.",
        "impact": "Breaks into harmful bits, dangerous to marine life."
    }
}

def load_and_preprocess_image(image_path: str) -> np.ndarray:
    """Load an image from disk and prepare it for prediction."""
    try:
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Failed to load image from: {image_path}")
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        img = img / 255.0
        return np.expand_dims(img, axis=0)
    except Exception as e:
        # Reduced logging
        traceback.print_exc()
        raise

def predict_image(model_path: str, image_path: str) -> dict:
    """Load the model and predict the label of the image."""
    try:
        # Suppress TensorFlow logging during model prediction
        tf.get_logger().setLevel('ERROR')
        # Disable TensorFlow debugging logs
        os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
        
        # Try to load the model - first as a directory, then as a file if that fails
        try:
            model = tf.keras.models.load_model(model_path)
        except:
            # If loading as directory fails, try with .keras extension
            model = tf.keras.models.load_model(f"{model_path}.keras")
    except Exception:
        traceback.print_exc()
        raise

    try:
        processed_img = load_and_preprocess_image(image_path)
    except Exception:
        traceback.print_exc()
        raise

    try:
        # Suppress verbose output from model.predict
        predictions = model.predict(processed_img, verbose=0)[0]
        label_idx = int(np.argmax(predictions))
        label = LABELS[label_idx]
        confidence = float(predictions[label_idx])
        info = LABEL_INFO.get(label, {})
        return {
            "label": label,
            "confidence": confidence,
            "info": info
        }
    except Exception:
        traceback.print_exc()
        raise
