import cv2
import numpy as np
import tensorflow as tf

LABELS = ['HDPE', 'LDPE', 'PET', 'PP', 'PS']
IMG_SIZE = 224

def predict_image(model_path, image_path):
    model = tf.keras.models.load_model(model_path)
    img = cv2.imread(image_path)
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE)) / 255.0
    img = np.expand_dims(img, axis=0)
    predictions = model.predict(img)[0]
    return {LABELS[i]: float(predictions[i]) for i in range(len(LABELS))}
