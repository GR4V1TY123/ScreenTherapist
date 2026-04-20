"""
Test suite for Screen Therapist Backend.
Run from project root:  pytest tests/ -v
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import date, timedelta

from main import app
from app.database import Base, get_db

# ─── In-memory test DB ────────────────────────────────────────────────────────
TEST_DB_URL = "sqlite:///./test_screen_therapist.db"
test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestSession  = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

def override_get_db():
    db = TestSession()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
Base.metadata.create_all(bind=test_engine)
client = TestClient(app)

# ─── Sample payload (exactly what Android sends) ─────────────────────────────
SAMPLE_PAYLOAD = {
    "user_id": "test_user_001",
    "metrics": {
        "screen_time_today":   "6h 45m (high)",
        "screen_time_weekly":  "41h (+12% increase)",
        "unlock_count_today":  "92 (very high)",
        "unlock_count_weekly": "610",
        "focus_score":         "38 (low)",
        "addiction_score":     "76 (high)",
        "productive_ratio":    "0.28 (low)",
        "late_night_usage":    "1h 50m (high)"
    },
    "apps": [
        {"name": "Instagram", "usage": "2h 10m",  "category": "entertainment"},
        {"name": "YouTube",   "usage": "1h 45m",  "category": "entertainment"},
        {"name": "WhatsApp",  "usage": "55m",      "category": "communication"},
        {"name": "Chrome",    "usage": "40m",      "category": "productive"},
    ],
    "flags": [
        "high_screen_time", "high_unlock_frequency", "late_night_usage",
        "low_productive_ratio", "high_dependency_on_instagram", "declining_focus_score"
    ]
}


def seed_multi_day_data(user_id: str, n_days: int = 14):
    """Seeds N days of data simulating worsening addiction + improving focus."""
    import random; random.seed(42)
    base_date = date.today() - timedelta(days=n_days)
    for i in range(n_days):
        d = base_date + timedelta(days=i)
        payload = {
            "user_id": user_id,
            "date": str(d),
            "metrics": {
                "screen_time_today":   f"{5 + i*0.1:.0f}h 0m",
                "screen_time_weekly":  "35h",
                "unlock_count_today":  f"{60 + i*2} (medium)",
                "unlock_count_weekly": "420",
                "focus_score":         f"{30 + i:.0f} (low)",
                "addiction_score":     f"{50 + i:.0f} (medium)",
                "productive_ratio":    f"{0.25 + i*0.01:.2f} (low)",
                "late_night_usage":    "45m"
            },
            "apps": [{"name": "Instagram", "usage": "1h 30m", "category": "entertainment"}],
            "flags": ["high_screen_time"] if i > 7 else []
        }
        r = client.post("/api/v1/summaries", json=payload)
        assert r.status_code == 201, f"Seed failed day {i}: {r.text}"


# ─── Tests ────────────────────────────────────────────────────────────────────

class TestHealth:
    def test_root(self):
        assert "running" in client.get("/").json()["message"]

    def test_health(self):
        assert client.get("/health").json()["status"] == "ok"


class TestSummaryIngestion:
    def test_submit_daily_summary(self):
        r = client.post("/api/v1/summaries", json=SAMPLE_PAYLOAD)
        assert r.status_code == 201, r.text
        d = r.json()
        assert d["screen_time_minutes"] == 405.0   # 6h 45m
        assert d["unlock_count_today"]  == 92
        assert d["focus_score"]         == 38.0
        assert d["addiction_score"]     == 76.0
        assert d["productive_ratio"]    == 0.28
        assert d["late_night_minutes"]  == 110.0   # 1h 50m
        assert len(d["app_usage"])      == 4
        assert len(d["flags"])          == 6

    def test_upsert_same_day(self):
        """Same user+date should UPDATE not duplicate."""
        modified = {**SAMPLE_PAYLOAD, "metrics": {**SAMPLE_PAYLOAD["metrics"], "addiction_score": "80 (very high)"}}
        r = client.post("/api/v1/summaries", json=modified)
        assert r.status_code == 201
        assert r.json()["addiction_score"] == 80.0

    def test_get_summaries(self):
        r = client.get("/api/v1/summaries/test_user_001")
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_get_latest(self):
        r = client.get("/api/v1/summaries/test_user_001/latest")
        assert r.status_code == 200

    def test_missing_user_404(self):
        assert client.get("/api/v1/summaries/ghost_user_xyz").status_code == 404


class TestDurationParsing:
    def test_hours_and_minutes(self):
        from app.utils import parse_duration_to_minutes
        assert parse_duration_to_minutes("6h 45m (high)") == 405.0

    def test_minutes_only(self):
        from app.utils import parse_duration_to_minutes
        assert parse_duration_to_minutes("55m") == 55.0

    def test_hours_with_pct(self):
        from app.utils import parse_duration_to_minutes
        assert parse_duration_to_minutes("41h (+12% increase)") == 2460.0

    def test_number_parsing(self):
        from app.utils import parse_number
        assert parse_number("92 (very high)") == 92.0
        assert parse_number("0.28 (low)")     == 0.28
        assert parse_number("610")            == 610.0


class TestTrends:
    @classmethod
    def setup_class(cls):
        seed_multi_day_data("trend_user", n_days=14)

    def test_get_trends(self):
        r = client.get("/api/v1/trends/trend_user?days=30")
        assert r.status_code == 200
        data = r.json()
        assert len(data) >= 7
        for pt in data:
            assert "date" in pt and "addiction_score" in pt and "focus_score" in pt

    def test_weekly_summary(self):
        r = client.get("/api/v1/trends/trend_user/weekly-summary")
        assert r.status_code == 200
        assert "comparison" in r.json()


class TestRegression:
    @classmethod
    def setup_class(cls):
        seed_multi_day_data("regress_user", n_days=14)

    def test_regression_runs(self):
        r = client.get("/api/v1/analysis/regress_user/regression?days=14")
        assert r.status_code == 200
        data = r.json()
        assert len(data) == 5
        metrics = {d["metric"] for d in data}
        assert {"addiction_score", "focus_score", "screen_time", "productive_ratio", "unlock_count"} == metrics

    def test_addiction_trending_up(self):
        r = client.get("/api/v1/analysis/regress_user/regression?days=14")
        addiction = next(d for d in r.json() if d["metric"] == "addiction_score")
        assert addiction["slope"] > 0
        assert addiction["direction"] == "increasing"

    def test_r_squared_in_range(self):
        for item in client.get("/api/v1/analysis/regress_user/regression?days=14").json():
            assert 0.0 <= item["r_squared"] <= 1.0

    def test_insufficient_data_422(self):
        payload = {**SAMPLE_PAYLOAD, "user_id": "one_day_user"}
        client.post("/api/v1/summaries", json=payload)
        assert client.get("/api/v1/analysis/one_day_user/regression").status_code == 422


class TestPersonalization:
    @classmethod
    def setup_class(cls):
        seed_multi_day_data("personal_user", n_days=14)

    def test_personalization(self):
        r = client.get("/api/v1/analysis/personal_user/personalization")
        assert r.status_code == 200
        d = r.json()
        for key in ["personal_avg_screen_time", "personal_avg_addiction", "personal_avg_focus",
                    "improvement_areas", "strengths"]:
            assert key in d
        assert isinstance(d["improvement_areas"], list)
        assert d["best_day"] is not None and d["worst_day"] is not None


class TestFullAnalysis:
    @classmethod
    def setup_class(cls):
        seed_multi_day_data("full_user", n_days=14)

    def test_full_analysis(self):
        r = client.get("/api/v1/analysis/full_user/full")
        assert r.status_code == 200
        d = r.json()
        for key in ["trends", "regression", "personalization", "summary"]:
            assert key in d
        assert d["data_points"] >= 7


def teardown_module(module):
    if os.path.exists("test_screen_therapist.db"):
        os.remove("test_screen_therapist.db")
