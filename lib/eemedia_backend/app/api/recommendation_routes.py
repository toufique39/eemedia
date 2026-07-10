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

    limit: int = 30


@router.post("/reels")

def recommend_reels(

    request: RecommendationRequest,

):

    reels = get_recommendations(

        request.user_id,

        request.limit,

    )
    recommended_ids = []
    for item in reels:

      recommended_ids.append(

        item["id"]

    )
    
    return {

    "recommended_reel_ids":

        recommended_ids

}