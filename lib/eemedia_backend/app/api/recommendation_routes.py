from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(
    prefix="/api/v1/recommendations",
    tags=["Recommendations"],
)


class RecommendationRequest(BaseModel):
    user_id: str
    limit: int = 20


@router.post("/reels")
async def get_recommendations(request: RecommendationRequest):
    """
    Temporary Recommendation API
    পরে এখানে AI Recommendation Engine যুক্ত হবে।
    """

    return {
        "success": True,
        "recommended_reel_ids": [],
        "message": "Recommendation API is working."
    }