import random


def apply_exploration(
    ranked,
    profile,
    exploration_ratio=0.20,
):
    """
    Inject random reels into
    recommendation list.

    80% Personalized
    20% Exploration
    """

    if len(ranked) < 10:
        return ranked

    personalized_count = int(
        len(ranked)
        * (1 - exploration_ratio)
    )

    personalized = ranked[
        :personalized_count
    ]

    remaining = ranked[
        personalized_count:
    ]

    random.shuffle(
        remaining
    )

    explored = remaining[
        : len(ranked)
        - personalized_count
    ]

    final_feed = (
        personalized
        + explored
    )

    return final_feed