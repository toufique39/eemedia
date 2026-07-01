from collections import defaultdict
from datetime import datetime, timezone
from typing import Any

from app.firebase_client import get_firestore_client


ENTERTAINMENT_LIMIT_SECONDS = 60  
FETCH_BUFFER = 5
MIN_WATCH_SECONDS = 10


class RecommendationService:
    """
    Hybrid recommendation engine, version 1.

    Score sources:
    - User interests and department-mapped topics
    - Previous watch interactions
    - Previous reactions
    - Education preference when entertainment limit is reached
    """  

   
    REACTION_WEIGHTS = {
        "like": 10,
        "love": 20,
        "wow": 8,
        "haha": 8,
        "polti": 8,
        "sad": 2,
        "angry": 2,
    }

    @staticmethod
    def _normalize(value: Any) -> str:
        return str(value or "").strip().lower()

    def get_recommended_reel_ids(
        self,
        user_id: str,
        limit: int,
    ) -> list[str]:
        db = get_firestore_client()

        user_doc = db.collection("users").document(user_id).get()

        if not user_doc.exists:
            return self._get_latest_reel_ids(limit)

        user_data = user_doc.to_dict() or {}

        user_interests = {
            self._normalize(topic)
            for topic in user_data.get("interests", [])
            if self._normalize(topic)
        }

        department = self._normalize(user_data.get("department"))
        department_topics = self._get_department_topics(department)
        preferred_topics = user_interests | department_topics

        watched_reel_ids, topic_preferences = (
            self._build_user_preference_profile(user_id=user_id)
        )

        limit_reached = self._has_reached_entertainment_limit(
            user_id=user_id
        )

        
        reel_docs = list(
            db.collection("reels")
            .order_by("createdAt", direction="DESCENDING")
            .limit(limit * FETCH_BUFFER)
            .stream()
        )

        now = datetime.now(timezone.utc)
        scored_reels: list[tuple[float, str]] = []

        for reel_doc in reel_docs:
            reel = reel_doc.to_dict() or {}
            reel_id = reel_doc.id
            category = self._normalize(reel.get("category"))
            sub_category = self._normalize(reel.get("subCategory"))

            if limit_reached and category == "entertainment":
                continue

            score = 0.0

            if reel_id in watched_reel_ids:
                score -= 50

            if sub_category in preferred_topics:
                score += 40

            score += topic_preferences.get(sub_category, 0)

            if limit_reached and category == "education":
                score += 30

            
            created_at = reel.get("createdAt")
            if created_at:
                age_days = (now - created_at).days
                score += max(0, 10 - age_days)

            scored_reels.append((score, reel_id))

        scored_reels.sort(key=lambda item: item[0], reverse=True)

        recommended_ids = [
            reel_id for _, reel_id in scored_reels[:limit]
        ]

        if not recommended_ids:
            return self._get_latest_reel_ids(limit)

        return recommended_ids

    def _build_user_preference_profile(
        self,
        user_id: str,
    ) -> tuple[set[str], dict[str, float]]:
        db = get_firestore_client()

        interactions = (
            db.collection("interactions")
            .where("userId", "==", user_id)
            .stream()
        )

        watched_reel_ids: set[str] = set()
        topic_preferences: dict[str, float] = defaultdict(float)

        for interaction_doc in interactions:
            interaction = interaction_doc.to_dict() or {}
            reel_id = self._normalize(interaction.get("itemId"))
            event_type = self._normalize(interaction.get("eventType"))
            event_value = interaction.get("eventValue", 0)
            sub_category = self._normalize(interaction.get("subCategory"))

            if reel_id:
                watched_reel_ids.add(reel_id)

            try:
                numeric_value = float(event_value)
            except (TypeError, ValueError):
                numeric_value = 0

            if event_type == "watch":
                
                if numeric_value < MIN_WATCH_SECONDS:
                    score = 0
                else:
                    score = min(numeric_value / 10, 30)
            else:
                score = self.REACTION_WEIGHTS.get(event_type, numeric_value)

            if sub_category:
                topic_preferences[sub_category] += score

        return watched_reel_ids, dict(topic_preferences)

    def _has_reached_entertainment_limit(
        self,
        user_id: str,
    ) -> bool:
        db = get_firestore_client()

       
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        screen_time_doc = (
            db.collection("user_screen_time")
            .document(user_id)
            .collection("daily")
            .document(today)
            .get()
        )

        if not screen_time_doc.exists:
            return False

        data = screen_time_doc.to_dict() or {}
        entertainment_seconds = int(data.get("entertainmentSeconds", 0))

        # ✅ constant ব্যবহার করো
        return entertainment_seconds >= ENTERTAINMENT_LIMIT_SECONDS

    @staticmethod
    def _get_department_topics(department: str) -> set[str]:
        mapping = {
            "iot & robotics engineering": {
                "iot", "robotics", "ai",
                "programming", "embedded systems",
            },
            "computer science": {
                "programming", "ai",
                "cyber security", "software development",
            },
            "software engineering": {
                "programming", "software development",
                "web development", "mobile app development", "ai",
            },
            "eee": {
                "electronics", "power systems",
                "circuit design", "embedded systems",
            },
        }
        return mapping.get(department, set())

    @staticmethod
    def _get_latest_reel_ids(limit: int) -> list[str]:
        db = get_firestore_client()
        reel_docs = (
            db.collection("reels")
            .order_by("createdAt", direction="DESCENDING")
            .limit(limit)
            .stream()
        )
        return [reel_doc.id for reel_doc in reel_docs]