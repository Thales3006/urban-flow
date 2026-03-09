# visualiza as images no player_info.json

import json
import base64
import io
from PIL import Image

def load_writings(json_path: str):
    with open(json_path, "r") as f:
        sessions = json.load(f)

    for session_idx, session in enumerate(sessions):
        writings = session.get("writings", [])
        for w_idx, w in enumerate(writings):
            png_bytes = base64.b64decode(w["image"])
            img = Image.open(io.BytesIO(png_bytes))

            prediction = w["prediction"]
            kind = w["kind"]

            print(f"Sessão {session_idx} | Writing {w_idx} | kind={kind} | prediction={prediction:.2%}")
            img.show()  # abre no visualizador padrão do sistema

load_writings("/home/thales/.local/share/godot/app_userdata/Urban Flow/player_info.json")