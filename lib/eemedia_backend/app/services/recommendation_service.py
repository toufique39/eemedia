from collections import defaultdict

from app.services.cold_start_service import (
    get_cold_start_reels,
)
from app.services.interaction_service import (
    build_user_profile,
)

from app.services.candidate_service import (
    get_candidate_reels,
)

from app.services.trending_service import (
    calculate_trending_score,
)

from app.services.exploration_service import (
    apply_exploration,
)

from app.services.freshness_service import (
    calculate_freshness_score,
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

    # ----------------------------
    # Personal Preference
    # ----------------------------

    score += profile["categories"].get(
        category,
        0,
    )

    score += profile["subCategories"].get(
        sub_category,
        0,
    )

    # ----------------------------
    # Trending Score
    # ----------------------------

    trending_score = calculate_trending_score(
        reel,
    )

    score += trending_score

    # ----------------------------
    # Freshness Score
    # ----------------------------

    freshness_score = calculate_freshness_score(
        reel,
    )

    score += freshness_score

    

    return score


def get_recommendations(
    user_id,
    limit=50,
    debug=True,
):

    print("\n========== START ==========")

    profile = build_user_profile(
        user_id,
    )

    if profile["interactionCount"] == 0:

        print("COLD START USER")

        docs = get_cold_start_reels(
            limit=limit,
        )

        reels = []

        for doc in docs:

            data = doc.to_dict()

            data["id"] = doc.id

            reels.append(data)

        return reels

    print("PROFILE =", profile)

    docs = get_candidate_reels(
        profile,
        limit=200,
    )

    print("TOTAL DOCS =", len(docs))

    ranked = []

    for doc in docs:

        reel = doc.to_dict()

        reel["id"] = doc.id

        score = _calculate_score(
            reel,
            profile,
        )

        # =====================================================
        # DEBUG MODE
        # =====================================================

        if debug:

            category = reel.get(
                "finalCategory",
                "",
            )

            sub_category = reel.get(
                "subCategory",
                "",
            )

            personal_score = (
                profile["categories"].get(
                    category,
                    0,
                )
                +
                profile["subCategories"].get(
                    sub_category,
                    0,
                )
            )

            trending_score = calculate_trending_score(
                reel,
            )

            freshness_score = calculate_freshness_score(
                reel,
            )

            print(f"""
==============================
REEL ID       : {doc.id}

Category      : {category}

SubCategory   : {sub_category}

Personal      : {personal_score}

Trending      : {trending_score}

Freshness     : {freshness_score}

Final Score   : {score}
==============================
""")

        ranked.append({

            "id": doc.id,

            "score": score,

            "category": reel.get(
                "finalCategory",
                "",
            ),

            "subCategory": reel.get(
                "subCategory",
                "",
            ),

            "reel": reel,

        })

    # ----------------------------
    # Ranking
    # ----------------------------

    ranked.sort(

        key=lambda x: x["score"],

        reverse=True,

    )

    # ----------------------------
    # Diversity
    # ----------------------------

    ranked = _apply_diversity(
        ranked,
    )

    # ----------------------------
    # Creator Diversity
    # ----------------------------

    ranked = _apply_creator_diversity(
        ranked,
    )

    # ----------------------------
    # Exploration
    # ----------------------------

    ranked = apply_exploration(
        ranked,
        profile,
    )

    ranked = ranked[:limit]

    print("RANKED =", len(ranked))

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

            "pipeline": {

                "personal": True,

                "trending": True,

                "freshness": True,

                "category_diversity": True,

                "creator_diversity": True,

                "exploration": True,

            }

        }

    }


def _apply_diversity(
    ranked,
):

    diversified = []

    category_counter = defaultdict(
        int,
    )

    for item in ranked:

        category = item["category"]

        if category_counter[
            category
        ] >= 2:

            continue

        diversified.append(
            item,
        )

        category_counter[
            category
        ] += 1

    used = {

        x["id"]

        for x in diversified

    }

    for item in ranked:

        if item["id"] not in used:

            diversified.append(
                item,
            )

    return diversified


def _apply_creator_diversity(
    ranked,
):

    diversified = []

    creator_counter = defaultdict(
        int,
    )

    skipped = []

    for item in ranked:

        creator = item[
            "reel"
        ].get(
            "userId",
            "",
        )

        if creator_counter[
            creator
        ] >= 2:

            skipped.append(
                item,
            )

            continue

        diversified.append(
            item,
        )

        creator_counter[
            creator
        ] += 1

    diversified.extend(
        skipped,
    )

    return diversified