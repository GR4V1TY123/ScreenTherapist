from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import date, timedelta
from typing import List
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import get_db
from app import models, schemas

router = APIRouter()


@router.get("/trends/{user_id}", response_model=List[schemas.TrendPoint])
def get_trends(
    user_id: str,
    days: int = Query(default=30, ge=7, le=365),
    db: Session = Depends(get_db)
):
    """Returns daily metric time series for the last N days."""
    cutoff = date.today() - timedelta(days=days)
    records = db.query(models.DailySummary).filter(
        and_(models.DailySummary.user_id == user_id, models.DailySummary.date >= cutoff)
    ).order_by(models.DailySummary.date.asc()).all()

    if not records:
        raise HTTPException(status_code=404, detail=f"No trend data for user '{user_id}'")

    return [
        schemas.TrendPoint(
            day=i + 1,
            date=r.date,
            screen_time_min=r.screen_time_minutes or 0,
            focus_score=r.focus_score or 0,
            addiction_score=r.addiction_score or 0,
            productive_ratio=r.productive_ratio or 0,
            unlock_count=r.unlock_count_today or 0,
        )
        for i, r in enumerate(records)
    ]


@router.get("/trends/{user_id}/weekly-summary")
def get_weekly_summary(user_id: str, db: Session = Depends(get_db)):
    """Week-over-week comparison for all metrics."""
    today     = date.today()
    this_week = today - timedelta(days=7)
    last_week = today - timedelta(days=14)

    def week_avg(start, end):
        records = db.query(models.DailySummary).filter(
            and_(models.DailySummary.user_id == user_id,
                 models.DailySummary.date >= start,
                 models.DailySummary.date < end)
        ).all()
        if not records:
            return None
        n = len(records)
        return {
            "days": n,
            "screen_time_min": sum(r.screen_time_minutes or 0 for r in records) / n,
            "focus_score":     sum(r.focus_score         or 0 for r in records) / n,
            "addiction_score": sum(r.addiction_score     or 0 for r in records) / n,
            "productive_ratio":sum(r.productive_ratio    or 0 for r in records) / n,
            "unlock_count":    sum(r.unlock_count_today  or 0 for r in records) / n,
        }

    this = week_avg(this_week, today)
    prev = week_avg(last_week, this_week)

    if not this:
        raise HTTPException(status_code=404, detail="Not enough data for this week")

    def pct_change(cur, pv):
        return round((cur - pv) / pv * 100, 1) if pv else None

    comparison = {}
    for key in ["screen_time_min", "focus_score", "addiction_score", "productive_ratio", "unlock_count"]:
        comparison[key] = {
            "this_week":  round(this[key], 2),
            "last_week":  round(prev[key], 2) if prev else None,
            "pct_change": pct_change(this[key], prev[key]) if prev else None,
        }

    return {"user_id": user_id, "comparison": comparison}
