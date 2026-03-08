# uvicorn server:app --reload --host :: --port 8000

from fastapi import FastAPI
import numpy as np
import tensorflow as tf
import base64
from PIL import Image
import io

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

    # Decodifica base64
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