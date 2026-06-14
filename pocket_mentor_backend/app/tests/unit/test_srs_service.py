import pytest
from datetime import datetime, timedelta
from app.services.srs_service import calculate_next_review, create_initial_srs_record
from app.db.models.srs_record import SRSRecord, SRSResponse


def _make_record(**kwargs) -> SRSRecord:
    defaults = {
        "id": "test-id",
        "card_id": "card-id",
        "user_id": "user-id",
        "ease_factor": 2.5,
        "interval_days": 1,
        "repetitions": 0,
        "next_review_at": datetime.utcnow(),
        "last_review_at": None,
        "last_response": None,
    }
    defaults.update(kwargs)
    record = SRSRecord()
    for k, v in defaults.items():
        setattr(record, k, v)
    return record


class TestSRSService:

    def test_initial_record_creation(self):
        data = create_initial_srs_record("card-1", "user-1")
        assert data["ease_factor"] == 2.5
        assert data["interval_days"] == 1
        assert data["repetitions"] == 0
        assert data["last_response"] is None

    def test_know_first_repetition(self):
        record = _make_record(repetitions=0, interval_days=1)
        result = calculate_next_review(record, SRSResponse.know)
        assert result["repetitions"] == 1
        assert result["interval_days"] == 1
        assert result["ease_factor"] >= 2.5

    def test_know_second_repetition(self):
        record = _make_record(repetitions=1, interval_days=1)
        result = calculate_next_review(record, SRSResponse.know)
        assert result["repetitions"] == 2
        assert result["interval_days"] == 6

    def test_know_third_repetition_uses_ef(self):
        record = _make_record(repetitions=2, interval_days=6, ease_factor=2.5)
        result = calculate_next_review(record, SRSResponse.know)
        assert result["repetitions"] == 3
        assert result["interval_days"] == round(6 * 2.5)

    def test_dont_know_resets_repetitions(self):
        record = _make_record(repetitions=5, interval_days=30, ease_factor=2.8)
        result = calculate_next_review(record, SRSResponse.dont_know)
        assert result["repetitions"] == 0
        assert result["interval_days"] == 1

    def test_dont_know_decreases_ease_factor(self):
        record = _make_record(repetitions=3, interval_days=10, ease_factor=2.5)
        result = calculate_next_review(record, SRSResponse.dont_know)
        assert result["ease_factor"] < 2.5

    def test_ease_factor_never_below_minimum(self):
        record = _make_record(repetitions=0, ease_factor=1.3)
        result = calculate_next_review(record, SRSResponse.dont_know)
        assert result["ease_factor"] >= 1.3

    def test_next_review_in_future_on_know(self):
        record = _make_record(repetitions=0)
        before = datetime.utcnow()
        result = calculate_next_review(record, SRSResponse.know)
        assert result["next_review_at"] > before

    def test_last_response_recorded(self):
        record = _make_record()
        result = calculate_next_review(record, SRSResponse.know)
        assert result["last_response"] == SRSResponse.know

        result2 = calculate_next_review(record, SRSResponse.dont_know)
        assert result2["last_response"] == SRSResponse.dont_know
