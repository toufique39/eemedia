import os

from google import genai
from google.genai import types

from dotenv import load_dotenv

from app.ai.prompts import VISION_PROMPT
from app.ai.models import ClassificationResult

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

def load_frames(frame_paths):

    images = []

    for path in frame_paths:

        with open(path, "rb") as f:

            images.append(

                types.Part.from_bytes(

                    data=f.read(),

                    mime_type="image/jpeg",

                )

            )

    return images
def classify_frames(frame_paths):

    frames = load_frames(frame_paths)

    response = client.models.generate_content(

    model="gemini-2.5-flash",

    contents=[

        VISION_PROMPT,

        *frames,

    ],

    config={

        "response_mime_type":"application/json",

        "response_schema":ClassificationResult,

    }

)

    return response.parsed
