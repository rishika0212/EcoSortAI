
## Getting Started

### Prerequisites

- Python 3.8+
- pip
- Flutter SDK (latest stable)
- (Optional) CUDA for GPU acceleration

### Backend Setup

1. Navigate to the backend directory:
    ```sh
    cd backend
    ```
2. Install dependencies:
    ```sh
    pip install -r requirements.txt
    ```
3. Start the FastAPI server:
    ```sh
    uvicorn app.main:app --host 0.0.0.0 --port 8000
    ```

### Frontend Setup

1. Navigate to the frontend directory:
    ```sh
    cd frontend
    ```
2. Get Flutter dependencies:
    ```sh
    flutter pub get
    ```
3. Run the app (choose your target: device, emulator, or web):
    ```sh
    flutter run
    ```

### Machine Learning Module

- All ML scripts and models are in the `ml/` directory.
**Model Type:** The project uses a Convolutional Neural Network (CNN) implemented with TensorFlow/Keras for image classification of waste items into 5 categories.
- To train a new model:
    ```sh
    cd ml
    python train.py
    ```
- To export or use the model for prediction, see `export_model.py` and `predict.py`.

## Usage

1. Start the backend server.
2. Run the frontend app on your device or browser.
3. Use the app to capture or upload images for waste classification.
4. The backend will process the image and return the predicted waste category using the ML model.

## File Descriptions

- `backend/`: FastAPI backend for API endpoints and business logic.
- `frontend/`: Flutter app for user interface.
- `ml/`: Python scripts for training, exporting, and running the ML model.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](LICENSE)

## Authors

- Rishika
- Saurav Kumar
