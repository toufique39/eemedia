from datetime import datetime, timezone


def calculate_trending_score(reel):

    score = 0

    # -------------------------
    # Views
    # -------------------------

    views = reel.get("views", 0)

    if views >= 30:
        score += 8

    elif views >= 20:
        score += 6

    elif views >= 10:
        score += 4

    elif views >= 5:
        score += 2

    # -------------------------
    # Reactions
    # -------------------------

    reactions = reel.get("reactions", {})

    reaction_count = len(reactions)

    if reaction_count >= 20:
        score += 6

    elif reaction_count >= 10:
        score += 4

    elif reaction_count >= 5:
        score += 2

    # -------------------------
    # Comments
    # -------------------------

    comment_count = reel.get("commentCount", 0)

    if comment_count >= 10:
        score += 6

    elif comment_count >= 5:
        score += 4

    elif comment_count >= 3:
        score += 2

    # -------------------------
    # Freshness
    # -------------------------

    created_at = reel.get("createdAt")

    if created_at:

        if hasattr(created_at, "to_datetime"):
            created_at = created_at.to_datetime()

        days = (
            datetime.now(timezone.utc) -
            created_at
        ).days

        if days == 0:
            score += 5

        elif days <= 3:
            score += 3

        elif days <= 6:
            score += 2

    return score