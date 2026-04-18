from sqlalchemy import Column, Integer, Float, String, Date, JSON, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


class DailySummary(Base):
    """
    One row per user per day. 
    Android app sends this daily — we store it long-term for trends + regression.
    """
    __tablename__ = "daily_summaries"

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(String, index=True, nullable=False)
    date         = Column(Date, index=True, nullable=False)
    created_at   = Column(DateTime, default=datetime.utcnow)

    # Core metrics (parsed from Android payload)
    screen_time_minutes    = Column(Float)   # e.g. 405 (from "6h 45m")
    screen_time_weekly_min = Column(Float)   # e.g. 2460 (from "41h")
    unlock_count_today     = Column(Integer) # 92
    unlock_count_weekly    = Column(Integer) # 610
    focus_score            = Column(Float)   # 38.0
    addiction_score        = Column(Float)   # 76.0
    productive_ratio       = Column(Float)   # 0.28
    late_night_minutes     = Column(Float)   # 110 (from "1h 50m")

    # Derived flags (list stored as JSON)
    flags                  = Column(JSON, default=list)

    # App usage breakdown stored as JSON list
    # [{"name": "Instagram", "usage_minutes": 130, "category": "entertainment"}, ...]
    app_usage              = Column(JSON, default=list)

    # Computed by backend on ingest
    computed_trend_label   = Column(String, nullable=True)  # "improving" | "worsening" | "stable"

    def __repr__(self):
        return f"<DailySummary user={self.user_id} date={self.date} addiction={self.addiction_score}>"
