from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import API Routers
from app.api.ai_routes import router as ai_router
from app.api.recommendation_routes import router as recommendation_router

app = FastAPI(
    title="EEmedia Backend API",
    description="AI Powered Social Media Backend",
    version="1.0.0",
)

# -----------------------------
# CORS
# -----------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Production এ নিজের Domain দেবে
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------
# Root Route
# -----------------------------
@app.get("/")
def root():
    return {
        "message": "Welcome to EEmedia Backend 🚀"
    }

# -----------------------------
# Health Check
# -----------------------------
@app.get("/health")
def health():
    return {
        "status": "ok"
    }

# -----------------------------
# Include Routers
# -----------------------------
app.include_router(ai_router)
app.include_router(recommendation_router)