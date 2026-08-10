from app.firebase.firebase_config import db


def _top_categories(profile, max_categories=3):
    """
    Return top N user categories sorted by score.
    """

    categories = profile.get("categories", {})

    if not categories:
        return []

    sorted_categories = sorted(
        categories.items(),
        key=lambda x: x[1],
        reverse=True,
    )

    return [
        item[0].strip().lower()
        for item in sorted_categories[:max_categories]
    ]


def get_candidate_reels(
    profile,
    limit=300,
):
    """
    Production Candidate Generator

    Sources:
    1. Top Categories
    2. Trending
    3. Random Exploration
    """

    # -----------------------------
    # Cold Start
    # -----------------------------

    categories = profile.get("categories", {})

    if not categories:

        docs = (
            db.collection("reels")
            .where("aiProcessed", "==", True)
            .where("status", "==", "completed")
            .limit(limit)
            .stream()
        )

        return list(docs)

    # -----------------------------
    # Top Categories
    # -----------------------------

    top_categories = _top_categories(profile)

    print("TOP CATEGORIES =", top_categories)

    candidate_docs = []
    seen = set()

    # Number of reels from each category
    per_category_limit = max(20, limit // 3)

    for category in top_categories:

        docs = (
            db.collection("reels")
            .where(
                "finalCategory",
                "==",
                category,
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
            .limit(per_category_limit)
            .stream()
        )

        for doc in docs:

            if doc.id in seen:
                continue

            seen.add(doc.id)
            candidate_docs.append(doc)

    # -----------------------------
    # Trending Pool
    # -----------------------------

    trending_docs = (
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
            "likes",
            direction="DESCENDING",
        )
        .limit(30)
        .stream()
    )

    for doc in trending_docs:

        if doc.id in seen:
            continue

        seen.add(doc.id)
        candidate_docs.append(doc)

    # -----------------------------
    # Random Exploration Pool
    # -----------------------------

    random_docs = (
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
        .limit(30)
        .stream()
    )

    for doc in random_docs:

        if doc.id in seen:
            continue

        seen.add(doc.id)
        candidate_docs.append(doc)

    print("TOTAL CANDIDATES =", len(candidate_docs))

    return candidate_docs