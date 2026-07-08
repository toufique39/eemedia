import cv2
import numpy as np
import os


BLUR_THRESHOLD = 80
DUPLICATE_THRESHOLD = 5


def is_blurry(frame):
    """
    Returns True if the frame is blurry.
    """
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    variance = cv2.Laplacian(
        gray,
        cv2.CV_64F,
    ).var()

    return variance < BLUR_THRESHOLD


def frame_difference(frame1, frame2):
    """
    Calculates average pixel difference between two frames.
    """

    diff = cv2.absdiff(frame1, frame2)

    return np.mean(diff)


def extract_frames(
    video_path: str,
    output_folder: str,
    number_of_frames: int = 8,
):
    """
    Extracts smart frames from a video.

    Features:
    - Blur filtering
    - Duplicate filtering
    - Resize
    """

    video = cv2.VideoCapture(video_path)

    if not video.isOpened():
        raise Exception("Cannot open video.")

    os.makedirs(
        output_folder,
        exist_ok=True,
    )

    total_frames = int(
        video.get(cv2.CAP_PROP_FRAME_COUNT)
    )

    if total_frames == 0:
        raise Exception("Video has no frames.")

    interval = max(
        1,
        total_frames // number_of_frames,
    )

    saved_frames = []

    previous_frame = None

    for i in range(number_of_frames):

        frame_number = i * interval

        video.set(
            cv2.CAP_PROP_POS_FRAMES,
            frame_number,
        )

        success, frame = video.read()

        if not success:
            print(f"Frame {i+1}: Read failed.")
            continue

        # Resize
        frame = cv2.resize(
            frame,
            (512, 288),
        )

        # Blur Detection
        if is_blurry(frame):
            print(f"Frame {i+1}: Blurry -> Skipped")
            continue

        # Duplicate Detection
        if previous_frame is not None:

            score = frame_difference(
                previous_frame,
                frame,
            )

            if score < DUPLICATE_THRESHOLD:
                print(
                    f"Frame {i+1}: Duplicate -> Skipped"
                )
                continue

        frame_path = os.path.join(
            output_folder,
            f"frame_{len(saved_frames)+1}.jpg",
        )

        cv2.imwrite(
            frame_path,
            frame,
        )

        saved_frames.append(frame_path)

        previous_frame = frame

        print(
            f"Frame Saved -> {frame_path}"
        )

    video.release()

    if len(saved_frames) == 0:
        raise Exception(
            "No valid frames extracted."
        )

    print(
        f"Successfully extracted {len(saved_frames)} frames."
    )

    return saved_frames


if __name__ == "__main__":

    frames = extract_frames(
        video_path="test.mp4",
        output_folder="frames",
    )

    print(frames)