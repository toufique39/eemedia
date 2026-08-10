from app.firebase.firebase_config import db


def get_cold_start_reels(
    limit=50,
):
    """
    Cold Start Feed

    Used when user has
    no interaction history.
    """

    docs = (
        db.collection("reels")
        .where(
            "aiProcessed",
            "==",
            True,
        )
        .where(
            "status",
            "==",
            "completed",
        )
        .order_by(
            "viewCount",
            direction="DESCENDING",
        )
        .limit(limit)
        .stream()
    )

    return list(docs)