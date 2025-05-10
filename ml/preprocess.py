import os
import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.utils import img_to_array, load_img

# Define your label columns
LABEL_COLUMNS = ["HDPE", "LDPE", "PET", "PP", "PS"]

def load_data(csv_path, img_dir, target_size=(224, 224)):
    df = pd.read_csv(csv_path)

    # Clean column names (remove whitespace or hidden characters)
    df.columns = df.columns.str.strip()

    images = []
    labels = []

    for idx, row in df.iterrows():
        filename = row["filename"].strip()
        label = row[LABEL_COLUMNS].values.astype(np.float32)

        img_path = os.path.join(img_dir, filename)
        try:
            img = load_img(img_path, target_size=target_size)
            img = img_to_array(img) / 255.0  # Normalize
            images.append(img)
            labels.append(label)
        except Exception as e:
            print(f"Error loading {img_path}: {e}")

    return np.array(images), np.array(labels)
