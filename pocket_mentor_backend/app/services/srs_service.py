"""
SM-2 Spaced Repetition Algorithm implementation.

Algorithm rules:
  - Quality 5 (know):     perfect response
  - Quality 1 (dont_know): complete blackout

Interval calculation:
  - If repetitions == 0 : interval = 1 day
  - If repetitions == 1 : interval = 6 days
  - If repetitions >= 2 : interval = round(prev_interval * ease_factor)

Ease factor (EF) update:
  EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  EF' never goes below 1.3

On "dont_know":
  - Reset repetitions to 0
  - Reset interval to 1 day
  - Decrease ease_factor
"""

from datetime import datetime, timedelta
from app.db.models.srs_record import SRSRecord, SRSResponse


QUALITY_KNOW = 5
QUALITY_DONT_KNOW = 1
MIN_EASE_FACTOR = 1.3
DEFAULT_EASE_FACTOR = 2.5


def _calculate_new_ease_factor(current_ef: float, quality: int) -> float:
    new_ef = current_ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    return max(MIN_EASE_FACTOR, round(new_ef, 2))


def calculate_next_review(record: SRSRecord, response: SRSResponse) -> dict:
    """
    Given an existing SRS record and a user response, compute the updated
    SRS fields. Returns a dict ready to be applied to the record.
    """
    quality = QUALITY_KNOW if response == SRSResponse.know else QUALITY_DONT_KNOW
    now = datetime.utcnow()

    if response == SRSResponse.dont_know:
        # Reset on failure
        new_repetitions = 0
        new_interval = 1
        new_ef = _calculate_new_ease_factor(record.ease_factor, quality)
    else:
        # Successful recall
        new_repetitions = record.repetitions + 1
        new_ef = _calculate_new_ease_factor(record.ease_factor, quality)

        if record.repetitions == 0:
            new_interval = 1
        elif record.repetitions == 1:
            new_interval = 6
        else:
            new_interval = round(record.interval_days * record.ease_factor)

    next_review = now + timedelta(days=new_interval)

    return {
        "ease_factor": new_ef,
        "interval_days": new_interval,
        "repetitions": new_repetitions,
        "next_review_at": next_review,
        "last_review_at": now,
        "last_response": response,
    }


def create_initial_srs_record(card_id: str, user_id: str) -> dict:
    """Create default SRS fields for a brand-new card."""
    return {
        "card_id": card_id,
        "user_id": user_id,
        "ease_factor": DEFAULT_EASE_FACTOR,
        "interval_days": 1,
        "repetitions": 0,
        "next_review_at": datetime.utcnow(),
        "last_review_at": None,
        "last_response": None,
    }
