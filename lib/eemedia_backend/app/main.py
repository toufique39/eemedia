from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.recommendations import router as recommendations_router

app = FastAPI(
    title="EEmedia Recommendation API",
    version="1.0.0",
    description=(
        "Backend API for EEmedia video recommendation system."
    ),
)

# Development CORS configuration.
# Production-এ allowed_origins নির্দিষ্ট domain দিয়ে replace করবো।
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(recommendations_router)


@app.get("/health")
async def health_check() -> dict:
    return {
        "status": "ok",
        "service": "eemedia-recommendation-api",
    }