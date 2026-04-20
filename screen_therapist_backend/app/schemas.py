from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import date as date_type
import re


# ─── Inbound from Android ───────────────────────────────────────────────────

class AppUsageItem(BaseModel):
    name: str
    usage: str            # "2h 10m" or "55m"
    category: str         # "entertainment" | "productive" | "communication"


class MetricsPayload(BaseModel):
    screen_time_today:    str   # "6h 45m (high)"
    screen_time_weekly:   str   # "41h (+12% increase)"
    unlock_count_today:   str   # "92 (very high)"
    unlock_count_weekly:  str   # "610"
    focus_score:          str   # "38 (low)"
    addiction_score:      str   # "76 (high)"
    productive_ratio:     str   # "0.28 (low)"
    late_night_usage:     str   # "1h 50m (high)"


class DailySummaryCreate(BaseModel):
    user_id:  str
    date:     Optional[date_type] = None   # defaults to today if omitted
    metrics:  MetricsPayload
    apps:     List[AppUsageItem]
    flags:    List[str] = []


# ─── Outbound to Android / Frontend ─────────────────────────────────────────

class DailySummaryResponse(BaseModel):
    id:                    int
    user_id:               str
    date:                  date_type
    screen_time_minutes:   float
    unlock_count_today:    int
    focus_score:           float
    addiction_score:       float
    productive_ratio:      float
    late_night_minutes:    float
    flags:                 List[str]
    app_usage:             list
    computed_trend_label:  Optional[str]

    class Config:
        from_attributes = True


class TrendPoint(BaseModel):
    day:             Optional[int] = None
    date:            date_type
    screen_time_min: float
    focus_score:     float
    addiction_score: float
    productive_ratio: float
    unlock_count:    int


class RegressionResult(BaseModel):
    metric:         str
    slope:          float     # positive = worsening, negative = improving
    r_squared:      float     # model fit quality (0-1)
    predicted_next: float     # predicted value for tomorrow
    direction:      str       # "increasing" | "decreasing" | "stable"
    interpretation: str       # human-readable


class PersonalizationResult(BaseModel):
    user_id:          str
    baseline_period:  str       # e.g. "last 14 days"
    personal_avg_screen_time: float
    personal_avg_addiction:   float
    personal_avg_focus:       float
    peak_usage_day:   Optional[str]
    best_day:         Optional[str]
    worst_day:        Optional[str]
    improvement_areas: List[str]
    strengths:         List[str]


class FullAnalysisResponse(BaseModel):
    user_id:         str
    data_points:     int
    trends:          List[TrendPoint]
    regression:      List[RegressionResult]
    personalization: PersonalizationResult
    summary:         str


class DataPointInput(BaseModel):
    day: int
    date: str
    screen_time_min: float
    focus_score: float
    addiction_score: float
    productive_ratio: float
    unlock_count: int

class AnalysisRequest(BaseModel):
    user_id: str = 'local_user'
    data_points: List[DataPointInput]
