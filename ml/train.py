from preprocess import load_data
from model import create_model
from sklearn.model_selection import train_test_split
import tensorflow as tf
import os

# Paths
CSV_PATH = "Dataset/train/_classes.csv"
IMG_DIR = "Dataset/train"
MODEL_SAVE_PATH = "saved_model/eco_sort_model.keras"  # Must end in .keras

# Load and split data
print("Loading training data...")
X, y = load_data(CSV_PATH, IMG_DIR)
print(f"Loaded {len(X)} samples.")

X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)

# Create model
model = create_model(input_shape=(224, 224, 3), num_classes=5)

# Callbacks
callbacks = [
    tf.keras.callbacks.ModelCheckpoint(
        filepath=MODEL_SAVE_PATH,
        save_best_only=True,
        monitor="val_loss",
        mode="min",
        verbose=1
    ),
    tf.keras.callbacks.EarlyStopping(
        monitor="val_loss",
        patience=5,
        restore_best_weights=True,
        verbose=1
    )
]

# Train model
history = model.fit(
    X_train, y_train,
    validation_data=(X_val, y_val),
    epochs=20,
    batch_size=32,
    callbacks=callbacks
)

print("Training complete.")
