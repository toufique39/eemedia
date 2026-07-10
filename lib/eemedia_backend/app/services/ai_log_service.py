import time

from firebase_admin import firestore

from app.firebase.firebase_config import db


def log_ai_success(
    reel_id: str,
    user_id: str,
    category: str,
    confidence: float,
    processing_time: float,
   
):

    db.collection("ai_logs").add({

        "reelId": reel_id,

        "userId": user_id,
         
        "aiCategory": category,

        "confidence": confidence,

        "processingTime": round(processing_time, 2),

        "status": "success",

        "error": None,

        "createdAt": firestore.SERVER_TIMESTAMP,

    })


def log_ai_failure(
    reel_id: str,
    user_id: str,
    error: str,
    processing_time: float,
):

    db.collection("ai_logs").add({

        "reelId": reel_id,

        "userId": user_id,

        "status": "failed",

        "error": error,

        "processingTime": round(processing_time, 2),

        "createdAt": firestore.SERVER_TIMESTAMP,

    })