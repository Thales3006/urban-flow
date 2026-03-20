# uvicorn server:app --reload --host :: --port 8141

from fastapi import FastAPI
import numpy as np
import tensorflow as tf
import base64
from PIL import Image
import io
from pydantic import BaseModel
from typing import Any
import json
from pathlib import Path
from fastapi import Request

DATA_FILE = Path("player_data.json")

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

# Carrega modelo TFLite
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

from tensorflow.keras.applications.mobilenet_v2 import preprocess_input


@app.post("/predict")
async def predict(data: dict):
    image_bytes = base64.b64decode(data["image"])
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

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
    DATA_FILE.write_text(
        json.dumps(sessions, indent=2, ensure_ascii=False),
        encoding="utf-8"
    )

@app.post("/player_data")
async def receive_player_data(request: Request):
    data = await request.json()
    
    if not isinstance(data, list):
        data = [data]
    
    existing = load_sessions()
    existing_ids = {s["session_id"] for s in existing if "session_id" in s}

    added = 0
    for session in data:
        if session.get("session_id") not in existing_ids:
            existing.append(session)
            added += 1

    save_sessions(existing)

    return {"status": "ok", "added": added, "total_sessions": len(existing)}