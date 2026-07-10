from collections import defaultdict
from app.firebase.firebase_config import db
from datetime import datetime, timezone

def get_user_interactions(user_id: str):
    """
    Fetch all interactions of a user.
    """

    docs = (
        db.collection("interactions")
        .where("userId", "==", user_id)
        .stream()
    )

    interactions = []

    for doc in docs:
        interactions.append(doc.to_dict())

    return interactions


def _interaction_weight(event_type, event_value):

    event_type = event_type.lower()

    if event_type == "watch":

        seconds = int(event_value)

        if seconds >= 60:
            return 10

        elif seconds >= 30:
            return 8

        elif seconds >= 15:
            return 5

        else:
            return 2

    if event_type == "like":
        return 6

    if event_type == "comment":
        return 8

    if event_type == "share":
        return 10

    if event_type == "save":
        return 12

    if event_type == "skip":
        return -5

    return 0


def aggregate_category_scores(interactions):

    scores = defaultdict(int)

    for interaction in interactions:

        category = interaction.get(
            "category",
            "Other",
        )

        base_weight = _interaction_weight(
            interaction.get("eventType", ""),
            interaction.get("eventValue", 0),
        )
        decay = _time_decay(
    interaction.get("timestamp")
)
        weight = base_weight * decay

        scores[category] += weight

    return dict(scores)


def aggregate_subcategory_scores(interactions):

    scores = defaultdict(int)

    for interaction in interactions:

        sub = interaction.get(
            "subCategory",
            "Other",
        )

        weight = _interaction_weight(
            interaction.get("eventType", ""),
            interaction.get("eventValue", 0),
        )

        scores[sub] += weight

    return dict(scores)


def build_user_profile(user_id):

    interactions = get_user_interactions(user_id)

    return {

        "categories":

            aggregate_category_scores(
                interactions,
            ),

        "subCategories":

            aggregate_subcategory_scores(
                interactions,
            ),

    }


def _time_decay(timestamp):

    if timestamp is None:
        return 0.5

    if hasattr(timestamp, "to_datetime"):
        interaction_time = timestamp.to_datetime()

    else:
        interaction_time = timestamp

    now = datetime.now(timezone.utc)

    days = (now - interaction_time).days

    if days <= 0:
        return 1.0

    if days <= 3:
        return 0.9

    if days <= 7:
        return 0.7

    if days <= 30:
        return 0.5

    return 0.2

if __name__ == "__main__":

    profile = build_user_profile(
        "YOUR_USER_ID"
    )

    print(profile)