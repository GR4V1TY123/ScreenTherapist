from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import date, timedelta
from typing import List
import statistics, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import get_db
from app import models, schemas
from app.utils import classify_trend, interpret_metric_trend

router = APIRouter()

def _linear_regression(x_vals, y_vals):
    n = len(x_vals)
    if n < 2: return 0.0, (y_vals[0] if y_vals else 0.0), 0.0
    x_mean = sum(x_vals) / n
    y_mean = sum(y_vals) / n
    ss_xy  = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_vals, y_vals))
    ss_xx  = sum((x - x_mean) ** 2 for x in x_vals)
    if ss_xx == 0: return 0.0, y_mean, 0.0
    slope     = ss_xy / ss_xx
    intercept = y_mean - slope * x_mean
    y_pred    = [slope * x + intercept for x in x_vals]
    ss_res    = sum((y - yp) ** 2 for y, yp in zip(y_vals, y_pred))
    ss_tot    = sum((y - y_mean) ** 2 for y in y_vals)
    r_sq      = 1 - (ss_res / ss_tot) if ss_tot != 0 else 0.0
    return slope, intercept, max(0.0, min(1.0, r_sq))

INPUT_METRIC_EXTRACTORS = {
    "screen_time":     lambda r: r.screen_time_min,
    "focus_score":     lambda r: r.focus_score,
    "addiction_score": lambda r: r.addiction_score,
    "productive_ratio":lambda r: r.productive_ratio * 100,
    "unlock_count":    lambda r: r.unlock_count,
}

@router.post("/generate", response_model=schemas.FullAnalysisResponse)
def generate_analysis(request: schemas.AnalysisRequest):
    records = request.data_points
    if not records: raise HTTPException(status_code=400, detail="No data points provided")
    n = len(records)
    x = list(range(n))

    trend_points = [
        schemas.TrendPoint(
            day=i + 1, date=r.date, 
            screen_time_min=r.screen_time_min, focus_score=r.focus_score,
            addiction_score=r.addiction_score, productive_ratio=r.productive_ratio,
            unlock_count=r.unlock_count,
        ) for i, r in enumerate(records)
    ]

    regression_results = []
    if n >= 3:
        for metric_name, extractor in INPUT_METRIC_EXTRACTORS.items():
            y = [extractor(r) for r in records]
            slope, intercept, r_sq = _linear_regression(x, y)
            predicted = max(0, slope * n + intercept)
            std = statistics.stdev(y) if len(y) > 1 else 1.0
            direction = classify_trend(slope, std)
            regression_results.append(schemas.RegressionResult(
                metric=metric_name, slope=round(slope, 4),
                r_squared=round(r_sq, 4), predicted_next=round(predicted, 2),
                direction=direction,
                interpretation=interpret_metric_trend(metric_name, direction, slope),
            ))

    avg_screen = sum(r.screen_time_min for r in records) / n
    avg_addiction = sum(r.addiction_score for r in records) / n
    avg_focus = sum(r.focus_score for r in records) / n
    avg_prod = sum(r.productive_ratio for r in records) / n
    avg_unlock = sum(r.unlock_count for r in records) / n

    sorted_r = sorted(records, key=lambda r: r.focus_score - r.addiction_score * 0.5)
    peak = max(records, key=lambda r: r.screen_time_min)

    improvement_areas, strengths = [], []
    if avg_addiction > 60: improvement_areas.append(f"Addiction score avg {avg_addiction:.0f} - high dependency")
    else: strengths.append(f"Healthy addiction score (avg {avg_addiction:.0f})")
    if avg_focus < 50: improvement_areas.append(f"Focus score avg {avg_focus:.0f} - needs improvement")
    else: strengths.append(f"Consistent focus (avg {avg_focus:.0f})")
    if avg_prod < 0.3: improvement_areas.append(f"Productive ratio {avg_prod:.0%} - mostly unproductive usage")
    else: strengths.append(f"Good productive ratio ({avg_prod:.0%})")
    if avg_screen > 360: improvement_areas.append(f"Screen time avg {avg_screen/60:.1f}h/day - exceeds 6h threshold")
    else: strengths.append(f"Screen time managed (avg {avg_screen/60:.1f}h/day)")
    if avg_unlock > 80: improvement_areas.append(f"Unlock frequency avg {avg_unlock:.0f}/day - compulsive pattern")
    else: strengths.append(f"Healthy unlock frequency (avg {avg_unlock:.0f}/day)")

    return schemas.FullAnalysisResponse(
        user_id=request.user_id,
        data_points=n,
        trends=trend_points,
        regression=regression_results,
        personalization=schemas.PersonalizationResult(
            user_id=request.user_id,
            baseline_period=f"last {n} days ({n} data points)",
            personal_avg_screen_time=round(avg_screen, 1), personal_avg_addiction=round(avg_addiction, 1),
            personal_avg_focus=round(avg_focus, 1), peak_usage_day=str(peak.date),
            best_day=str(sorted_r[-1].date) if sorted_r else None, worst_day=str(sorted_r[0].date) if sorted_r else None,
            improvement_areas=improvement_areas, strengths=strengths,
        ),
        summary="Analysis generated fully from private local device data."
    )

