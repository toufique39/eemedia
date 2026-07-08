from app.ai.frame_extractor import extract_frames


def extract_video_frames(
    video_path: str,
    temp_dir: str,
):
    return extract_frames(
        video_path=video_path,
        output_folder=f"{temp_dir}/frames",
    )