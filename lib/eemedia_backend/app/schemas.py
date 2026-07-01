from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    user_id: str = Field(
        min_length=1,
        description="Firebase Authentication user UID",
    )
    limit: int = Field(
        default=20,
        ge=1,
        le=100,
        description="Maximum number of reel IDs to return",
    )


class RecommendationResponse(BaseModel):
    user_id: str
    recommended_reel_ids: list[str]
    strategy: str