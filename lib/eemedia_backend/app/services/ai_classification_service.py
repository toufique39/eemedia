import json
import shutil
from app.ai.gemini_classifier import classify_frames
from app.services.video_download_service import download_video
from app.services.frame_extraction_service import extract_video_frames

from app.services.firestore_update_service import (
    update_ai_result,
    update_ai_error,
)

import time

from app.services.ai_log_service import (

    log_ai_success,
    log_ai_failure,
)


def classify_reel(reel_id, video_url):

    print("\n========== AI START ==========")
    print("Reel ID :", reel_id)
    print("Video URL :", video_url)

    start_time = time.perf_counter()
    temp_dir = None

    try:

        print("STEP-1 : Downloading video...")
        temp_dir, video_path = download_video(video_url)

        print("Video Path :", video_path)

        print("STEP-2 : Extracting Frames...")
        frames = extract_video_frames(
            video_path,
            temp_dir,
        )

        print("Frames :", frames)

        print("STEP-3 : Gemini Classifying...")
        result = classify_frames(frames)

        print("Gemini Result :", result)

        print("STEP-4 : Updating Firestore...")

        update_ai_result(
            reel_id,
            {
                "category": result.category,
                "confidence": result.confidence,
                "reason": result.reason,
            },
        )

        print("Firestore Updated Successfully")

        processing_time = time.perf_counter() - start_time

        log_ai_success(
            reel_id=reel_id,
            user_id="",
            category=result.category,
            confidence=result.confidence,
            processing_time=processing_time,
        )

        print("AI SUCCESS")

    except Exception as e:

        print("\n========== AI ERROR ==========")
        print(type(e))
        print(e)

        processing_time = time.perf_counter() - start_time

        update_ai_error(reel_id, e)

        log_ai_failure(
            reel_id=reel_id,
            user_id="",
            error=str(e),
            processing_time=processing_time,
        )

    finally:

        if temp_dir:
            shutil.rmtree(
                temp_dir,
                ignore_errors=True,
            )

        print("========== AI END ==========\n")