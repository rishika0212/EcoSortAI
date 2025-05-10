import tensorflow as tf

def export_model(model, export_path="exported_model.keras"):
    # Save model in the native Keras format
    model.save(export_path)
    print(f"Model exported to {export_path}")

# Run this when executing the script directly
if __name__ == "__main__":
    model = tf.keras.models.load_model("saved_model/eco_sort_model.keras")
    export_model(model)