from app.firebase.firebase_config import db


def get_candidate_reels(
    profile,
    limit=300,
):
    """
    Returns candidate reels based on
    user's strongest category interest.
    """

    categories = profile.get(
        "categories",
        {},
    )

    if not categories:

        docs = (
            db.collection("reels")
            .where("aiProcessed", "==", True)
            .where("status", "==", "completed")
            .limit(limit)
            .stream()
        )

        return list(docs)

    # Highest scored category
    top_category = max(
        categories,
        key=categories.get,
    )

    docs = (
        db.collection("reels")
        .where(
            "finalCategory",
            "==",
            top_category,
        )
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
        .limit(limit)
        .stream()
    )

    return list(docs)