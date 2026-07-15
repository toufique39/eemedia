from app.firebase.firebase_config import db
from app.services.interaction_service import build_user_profile
from collections import defaultdict
from collections import defaultdict
from app.services.candidate_service import (
    get_candidate_reels,
)
def _calculate_score(
    reel,
    profile,
):
    score = 0

    print(
        f"""
     -----------------------------------
     REEL ID        : {reel.get("id")}
     CATEGORY       : {reel.get("finalCategory")}
     SUBCATEGORY    : {reel.get("subCategory")}
     FINAL SCORE    : {score}
    
     """
    )

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
    limit=50,
    debug=False,
):

    profile = build_user_profile(user_id)

    docs = get_candidate_reels(profile, limit=200)

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

            "category": reel.get("finalCategory", ""),

            "subCategory": reel.get("subCategory", ""),

            "reel": reel,
        })

        ranked.sort(
          key=lambda x: x["score"],
          reverse=True,
)

        ranked = _apply_diversity(ranked)
        ranked = _apply_creator_diversity(ranked)

        ranked = ranked[:limit]

    if not debug:
        return ranked

    return {
        "recommended": ranked,

        "debug": {

            "category_scores":
                profile["categories"],

            "subcategory_scores":
                profile["subCategories"],

            "candidate_count":
                len(docs),

            "returned_count":
                len(ranked),
        }
    }
def _apply_diversity(ranked):

    diversified = []

    category_counter = defaultdict(int)

    for item in ranked:

        category = item["category"]


        if category_counter[category] >= 2:
            continue

        diversified.append(item)

        category_counter[category] += 1

   
    used = {x["id"] for x in diversified}

    for item in ranked:

        if item["id"] not in used:
            diversified.append(item)

    return diversified


def _apply_creator_diversity(ranked):

    diversified = []

    creator_counter = defaultdict(int)

    skipped = []

    for item in ranked:

        creator = item["reel"].get("userId", "")

        if creator_counter[creator] >= 2:
            skipped.append(item)
            continue

        diversified.append(item)

        creator_counter[creator] += 1

    diversified.extend(skipped)

    return diversified