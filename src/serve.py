import os, boto3
import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

ARTIFACT_BUCKET = os.environ["ARTIFACT_BUCKET"]
MODEL_KEY = "artifacts/current/model.joblib"
MODEL_PATH = os.path.expanduser("~/models/model.joblib")


def download_model():
    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
    try:
        s3 = boto3.client('s3')
        s3.download_file(ARTIFACT_BUCKET, MODEL_KEY, MODEL_PATH)
        print("Model đã được tải xuống từ AWS S3.")
    except Exception as e:
        print(f"Notice: S3 download error: {e}")


if not os.path.exists(MODEL_PATH):
    try:
        download_model()
    except Exception as e:
        print(f"Could not download model: {e}")

if os.path.exists(MODEL_PATH):
    model = joblib.load(MODEL_PATH)
else:
    model = None


class ScoreRequest(BaseModel):
    features: list[float]


@app.get("/healthz")
def healthz():
    """
    Endpoint kiem tra suc khoe server.
    """
    return {"status": "ok"}


@app.post("/score")
def score(req: ScoreRequest):
    """
    Endpoint suy luan chinh.
    """
    if len(req.features) != 10:
        raise HTTPException(
            status_code=400, detail="Expected 10 features (adult income)"
        )

    global model
    if model is None:
        if os.path.exists(MODEL_PATH):
            model = joblib.load(MODEL_PATH)
        else:
            raise HTTPException(
                status_code=500, detail="Model file not found or not loaded"
            )

    pred = int(model.predict([req.features])[0])
    label = "thu_nhap_cao" if pred == 1 else "thu_nhap_thap"
    return {"prediction": pred, "label": label}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
