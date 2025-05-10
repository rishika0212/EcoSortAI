from fastapi import APIRouter, UploadFile, File, HTTPException
from pathlib import Path
import shutil
import traceback
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))
from ml.predict import predict_image

router = APIRouter(prefix="/ml", tags=["ML"])

BASE_DIR = Path(__file__).resolve().parent.parent.parent
STATIC_DIR = BASE_DIR / "backend" / "static"
MODEL_PATH = Path(__file__).resolve().parent.parent.parent.parent / "ml" / "exported_model"


@router.post("/predict")
async def classify_image(file: UploadFile = File(...)):
    try:
        # Reduced logging
        STATIC_DIR.mkdir(parents=True, exist_ok=True)

        file_location = STATIC_DIR / file.filename
        
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        result = predict_image(str(MODEL_PATH), str(file_location))
        
        return {
            "label": result["label"],
            "confidence": result["confidence"],
            "info": result.get("info", {})
        }

    except Exception as e:
        print(f"❌ Exception in /ml/predict: {str(e)}")
        print(f"Model path: {MODEL_PATH}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

    finally:
        if file_location.exists():
            file_location.unlink()
