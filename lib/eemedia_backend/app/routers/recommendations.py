import logging
from fastapi import APIRouter, HTTPException
from httpx import request 
from app.schemas import (
    RecommendationRequest,
    RecommendationResponse,
)
from app.services.recommendation_service import (
    RecommendationService,
)


logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/recommendations",
    tags=["Recommendations"],
)

recommendation_service = RecommendationService()

@router.post(
    "/reels",
    response_model=RecommendationResponse,
)
async def get_recommended_reels(
    recommendation_request: RecommendationRequest,
) -> RecommendationResponse:
    try:
        
        reel_ids = recommendation_service.get_recommended_reel_ids(
            user_id=recommendation_request.user_id,
            limit=recommendation_request.limit,
        )

        return RecommendationResponse(
            user_id=recommendation_request.user_id,
            recommended_reel_ids=reel_ids,
            strategy="hybrid_v1_firestore",
        )

    except FileNotFoundError as error:
        logger.error(f"Configuration or data file missing: {error}")
        raise HTTPException(
            status_code=500,
            detail=str(error),
        ) from error

    except Exception as error:
       
        logger.exception("Recommendation API unexpected error")
        raise HTTPException(
            status_code=500,
            detail="Could not generate recommendations.",
        ) from error