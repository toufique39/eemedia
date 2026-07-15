from fastapi import APIRouter
from pydantic import BaseModel

from app.services.recommendation_service import (
    get_recommendations,
)

router = APIRouter(

    prefix="/api/v1/recommendations",

    tags=["Recommendations"],

)


class RecommendationRequest(BaseModel):

          user_id: str
          limit: int = 20
          debug: bool = False


@router.post("/reels")
def recommend_reels(
    request: RecommendationRequest,
):

    result = get_recommendations(

        user_id=request.user_id,

        limit=request.limit,

        debug=request.debug,

    )

    if request.debug:

        recommended_ids = []

        for item in result["recommended"]:

            recommended_ids.append({

                "id": item["id"],

                "score": item["score"],

                "category": item["category"],

                "subCategory": item["subCategory"],

            })

        return {

            "recommended_reel_ids":
                recommended_ids,

            "debug":
                result["debug"]

        }

    recommended_ids = []

    for item in result:

        recommended_ids.append(
            item["id"]
        )

    return {

        "recommended_reel_ids":
            recommended_ids

    }