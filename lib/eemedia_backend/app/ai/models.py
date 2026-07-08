from pydantic import BaseModel


class ClassificationResult(BaseModel):

    category: str

    confidence: float

    reason: str