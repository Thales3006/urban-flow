# uvicorn server:app --reload --host :: --port 8141

from fastapi import FastAPI, HTTPException, Request
import numpy as np
import tensorflow as tf
import base64
import binascii
from PIL import Image, UnidentifiedImageError
import io
from pydantic import BaseModel
import json
import os
import tempfile
from pathlib import Path

DATA_FILE = Path("player_data.json")
MODEL_PATH = Path("model.tflite")

CLASSES = [
    "Reciclagem",
    #"Eletricidade",
    "Saneamento",
    "Hospital",
    #"Parque",
    #"Comércio",
    #"Ônibus",
    "Escola",
    #"Indústria",
    #"Ciclovia",
    #"Metrô",
    #"Aeroporto",
    "Moradia",
    "nonsense"
]

NUM_CLASSES = len(CLASSES)

IMG_WIDTH, IMG_HEIGHT = 324, 324

app = FastAPI()

if not MODEL_PATH.exists():
    raise RuntimeError(
        f"Model file not found at {MODEL_PATH.resolve()} — "
        "run the server from the server_predict/ directory."
    )

# Carrega modelo TFLite
interpreter = tf.lite.Interpreter(model_path=str(MODEL_PATH))
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

from tensorflow.keras.applications.mobilenet_v2 import preprocess_input


class PredictRequest(BaseModel):
    image: str


@app.post("/predict")
async def predict(data: PredictRequest):
    try:
        image_bytes = base64.b64decode(data.image, validate=True)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except (binascii.Error, UnidentifiedImageError) as e:
        raise HTTPException(status_code=400, detail=f"Invalid image data: {e}")

    # Resize
    image = image.resize((IMG_WIDTH, IMG_HEIGHT))
    input_data = np.array(image, dtype=np.float32)
    input_data = input_data[..., ::-1]
    input_data = preprocess_input(input_data)
    input_data = np.expand_dims(input_data, axis=0)

    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

    output = interpreter.get_tensor(output_details[0]['index'])[0]

    result = {
        CLASSES[i]: float(output[i])
        for i in range(len(CLASSES))
    }

    return {"result": result}

def load_sessions() -> list:
    if not DATA_FILE.exists():
        return []
    try:
        return json.loads(DATA_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []

def save_sessions(sessions: list) -> None:
    # Write to a temp file then atomically replace, so a concurrent
    # request or a crash mid-write can never leave a corrupt/partial file.
    fd, tmp_path = tempfile.mkstemp(dir=DATA_FILE.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(sessions, f, indent=2, ensure_ascii=False)
        os.replace(tmp_path, DATA_FILE)
    except Exception:
        os.unlink(tmp_path)
        raise

@app.post("/player_data")
async def receive_player_data(request: Request):
    try:
        data = await request.json()
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON body")

    if not isinstance(data, list):
        data = [data]

    for session in data:
        if not isinstance(session, dict) or "session_id" not in session:
            raise HTTPException(
                status_code=400,
                detail="Each session must be an object with a session_id",
            )

    existing = load_sessions()
    # Índice por session_id para upsert
    index = {s["session_id"]: i for i, s in enumerate(existing) if "session_id" in s}

    added = 0
    updated = 0
    for session in data:
        sid = session["session_id"]
        if sid in index:
            existing[index[sid]] = session
            updated += 1
        else:
            existing.append(session)
            index[sid] = len(existing) - 1
            added += 1

    save_sessions(existing)
    return {"status": "ok", "added": added, "updated": updated, "total_sessions": len(existing)}