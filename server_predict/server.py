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
    #"Escola",
    #"Indústria",
    #"Ciclovia",
    #"Metrô",
    #"Aeroporto",
    "Moradia"
]

NUM_CLASSES = len(CLASSES)

app = FastAPI()

interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

@app.post("/predict")
async def predict(data: dict):
    # decodifica base64
    image_bytes = base64.b64decode(data["image"])
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((224, 224))
    input_data = np.expand_dims(np.array(image, dtype=np.float32), axis=0)

    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])[0]

    result = {
        CLASSES[i]: float(output[i])
        for i in range(len(CLASSES))
    }

    return {"result": result}