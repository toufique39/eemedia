from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel

from app.services.ai_classification_service import classify_reel

router = APIRouter(
    prefix="/api/v1/ai",
    tags=["AI"],
)


class ClassifyRequest(BaseModel):
    reel_id: str
    video_url: str


@router.post("/classify-reel")
async def classify_video(
    request: ClassifyRequest,
    background_tasks: BackgroundTasks,
):

    background_tasks.add_task(

        classify_reel,

        request.reel_id,

        request.video_url,

    )

    return {
        "success": True,
        "message": "AI Classification Started"
    }