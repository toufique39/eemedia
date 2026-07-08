from app.firebase.firebase_config import db


def update_ai_result(
    reel_id,
    result,
):

    db.collection("reels").document(reel_id).update({

        "aiCategory": result["category"].lower(),

        "finalCategory": result["category"].lower(),

        "confidence": result["confidence"],

        "reason": result["reason"],

        "aiProcessed": True,

        "status": "completed",

    })


def update_ai_error(
    reel_id,
    error,
):

    db.collection("reels").document(reel_id).update({

        "status": "failed",

        "aiProcessed": False,

        "error": str(error),

    })