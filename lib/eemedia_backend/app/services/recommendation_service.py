from app.firebase.firebase_config import db
from app.services.interaction_service import build_user_profile
from app.services.candidate_service import (
    get_candidate_reels,
)
def _calculate_score(
    reel,
    profile,
):
    score = 0

    category = reel.get(
        "finalCategory",
        "",
    )

    sub_category = reel.get(
        "subCategory",
        "",
    )

    # Category Preference
    score += profile["categories"].get(
        category,
        0,
    )

    # SubCategory Preference
    score += profile["subCategories"].get(
        sub_category,
        0,
    )

    return score


def get_recommendations(
    user_id,
    limit=30,
):

    profile = build_user_profile(user_id)
    docs = get_candidate_reels(profile, limit=300)

    ranked = []

    for doc in docs:

        reel = doc.to_dict()

        reel["id"] = doc.id

        score = _calculate_score(
            reel,
            profile,
        )

        ranked.append({

            "id": doc.id,

            "score": score,

            "reel": reel,

        })

    ranked.sort(

        key=lambda x: x["score"],

        reverse=True,

    )

    return ranked[:limit]