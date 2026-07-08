import os
import tempfile
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

MAX_VIDEO_SIZE_MB = 50
REQUEST_TIMEOUT = 30


def _create_session():

    retry = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[
            500,
            502,
            503,
            504,
        ],
    )

    session = requests.Session()

    adapter = HTTPAdapter(max_retries=retry)

    session.mount("http://", adapter)
    session.mount("https://", adapter)

    return session


def download_video(video_url: str):

    if not video_url.startswith("http"):
        raise ValueError("Invalid video url")

    temp_dir = tempfile.mkdtemp()

    video_path = os.path.join(
        temp_dir,
        "video.mp4",
    )

    session = _create_session()

    print("Downloading video...")

    response = session.get(
        video_url,
        timeout=REQUEST_TIMEOUT,
        stream=True,
    )

    response.raise_for_status()

    total_size = 0

    with open(video_path, "wb") as file:

        for chunk in response.iter_content(8192):

            if not chunk:
                continue

            total_size += len(chunk)

            file.write(chunk)

    size_mb = total_size / (1024 * 1024)

    print(f"Video Size : {size_mb:.2f} MB")

    if size_mb > MAX_VIDEO_SIZE_MB:

        raise Exception(
            f"Video too large ({size_mb:.2f} MB)"
        )

    print("Download Completed")

    return temp_dir, video_path