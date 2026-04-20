from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import date, datetime
from typing import List, Optional
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import get_db
from app import models, schemas
from app.utils import parse_duration_to_minutes, parse_number

router = APIRouter()


def _parse_and_store(payload: schemas.DailySummaryCreate, db: Session) -> models.DailySummary:
    summary_date = payload.date if payload.date else datetime.today().date()

    screen_time_min   = parse_duration_to_minutes(payload.metrics.screen_time_today)
    weekly_screen_min = parse_duration_to_minutes(payload.metrics.screen_time_weekly)
    unlock_today      = int(parse_number(payload.metrics.unlock_count_today))
    unlock_weekly     = int(parse_number(payload.metrics.unlock_count_weekly))
    focus             = parse_number(payload.metrics.focus_score)
    addiction         = parse_number(payload.metrics.addiction_score)
    productive        = parse_number(payload.metrics.productive_ratio)
    late_night        = parse_duration_to_minutes(payload.metrics.late_night_usage)

    app_usage_parsed = []
    for app in payload.apps:
        app_usage_parsed.append({
            "name":          app.name,
            "usage_minutes": parse_duration_to_minutes(app.usage),
            "category":      app.category
        })

    existing = db.query(models.DailySummary).filter(
        and_(
            models.DailySummary.user_id == payload.user_id,
            models.DailySummary.date    == summary_date
        )
    ).first()

    if existing:
        existing.screen_time_minutes    = screen_time_min
        existing.screen_time_weekly_min = weekly_screen_min
        existing.unlock_count_today     = unlock_today
        existing.unlock_count_weekly    = unlock_weekly
        existing.focus_score            = focus
        existing.addiction_score        = addiction
        existing.productive_ratio       = productive
        existing.late_night_minutes     = late_night
        existing.flags                  = payload.flags
        existing.app_usage              = app_usage_parsed
        db.commit()
        db.refresh(existing)
        return existing
    else:
        record = models.DailySummary(
            user_id                = payload.user_id,
            date                   = summary_date,
            screen_time_minutes    = screen_time_min,
            screen_time_weekly_min = weekly_screen_min,
            unlock_count_today     = unlock_today,
            unlock_count_weekly    = unlock_weekly,
            focus_score            = focus,
            addiction_score        = addiction,
            productive_ratio       = productive,
            late_night_minutes     = late_night,
            flags                  = payload.flags,
            app_usage              = app_usage_parsed,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return record


@router.post("/summaries", response_model=schemas.DailySummaryResponse, status_code=201)
def submit_daily_summary(payload: schemas.DailySummaryCreate, db: Session = Depends(get_db)):
    """Android calls this once per day with the metrics payload."""
    record = _parse_and_store(payload, db)
    return record


@router.get("/summaries/{user_id}", response_model=List[schemas.DailySummaryResponse])
def get_user_summaries(user_id: str, days: int = 30, db: Session = Depends(get_db)):
    """Returns last N days of stored summaries for a user."""
    from datetime import timedelta
    cutoff = date.today() - timedelta(days=days)
    records = db.query(models.DailySummary).filter(
        and_(models.DailySummary.user_id == user_id, models.DailySummary.date >= cutoff)
    ).order_by(models.DailySummary.date.desc()).all()
    if not records:
        raise HTTPException(status_code=404, detail=f"No data found for user '{user_id}'")
    return records


@router.get("/summaries/{user_id}/latest", response_model=schemas.DailySummaryResponse)
def get_latest_summary(user_id: str, db: Session = Depends(get_db)):
    """Returns the most recent summary for a user."""
    record = db.query(models.DailySummary).filter(
        models.DailySummary.user_id == user_id
    ).order_by(models.DailySummary.date.desc()).first()
    if not record:
        raise HTTPException(status_code=404, detail=f"No data for user '{user_id}'")
    return record
