from datetime import datetime, timezone


def calculate_freshness_score(reel):

    timestamp = reel.get("createdAt")

    if timestamp is None:
        return 0

    if hasattr(timestamp, "to_datetime"):
        created = timestamp.to_datetime()
    else:
        created = timestamp

    now = datetime.now(timezone.utc)

    hours = (now - created).total_seconds() / 3600

    if hours <= 1:
        return 10

    elif hours <= 6:
        return 8

    elif hours <= 24:
        return 5

    elif hours <= 72:
        return 2

    return 0