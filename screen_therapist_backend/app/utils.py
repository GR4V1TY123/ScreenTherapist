import re
from typing import Optional


def parse_duration_to_minutes(duration_str: str) -> float:
    """
    Parses Android duration strings into minutes.
    
    Examples:
        "6h 45m (high)"  → 405.0
        "1h 50m (high)"  → 110.0
        "55m"            → 55.0
        "2h 10m"         → 130.0
        "41h (+12% increase)" → 2460.0
    """
    # Strip everything in parentheses and extra words
    cleaned = re.sub(r'\(.*?\)', '', duration_str).strip()
    cleaned = re.sub(r'\+\d+%.*', '', cleaned).strip()  # strip "+12% increase"

    hours   = 0.0
    minutes = 0.0

    h_match = re.search(r'(\d+(?:\.\d+)?)\s*h', cleaned)
    m_match = re.search(r'(\d+(?:\.\d+)?)\s*m', cleaned)

    if h_match:
        hours = float(h_match.group(1))
    if m_match:
        minutes = float(m_match.group(1))

    return hours * 60 + minutes


def parse_number(value_str: str) -> float:
    """
    Parses Android number strings.
    
    Examples:
        "92 (very high)" → 92.0
        "76 (high)"      → 76.0
        "0.28 (low)"     → 0.28
        "610"            → 610.0
    """
    match = re.search(r'[\d.]+', value_str)
    if match:
        return float(match.group())
    raise ValueError(f"Cannot parse number from: {value_str!r}")


def severity_label(value_str: str) -> Optional[str]:
    """Extracts the severity label from a metrics string, e.g. 'high', 'low'."""
    match = re.search(r'\((.*?)\)', value_str)
    return match.group(1).lower() if match else None


def classify_trend(slope: float, std: float = 1.0) -> str:
    """
    Classify a regression slope as increasing/stable/decreasing.
    Uses std deviation to avoid noise calling everything a trend.
    """
    threshold = max(0.5, std * 0.1)
    if slope > threshold:
        return "increasing"
    elif slope < -threshold:
        return "decreasing"
    else:
        return "stable"


def interpret_metric_trend(metric: str, direction: str, slope: float) -> str:
    """Human-readable interpretation of a trend direction for a given metric."""
    good_when_decreasing = {"addiction_score", "screen_time", "unlock_count", "late_night"}
    good_when_increasing = {"focus_score", "productive_ratio"}

    is_good = (
        (direction == "decreasing" and metric in good_when_decreasing) or
        (direction == "increasing" and metric in good_when_increasing)
    )

    abs_slope = abs(slope)
    magnitude = "rapidly" if abs_slope > 5 else "gradually" if abs_slope > 1 else "slightly"

    if direction == "stable":
        return f"Your {metric.replace('_', ' ')} has been stable recently."
    elif is_good:
        return f"✅ Your {metric.replace('_', ' ')} is {magnitude} improving."
    else:
        return f"⚠️ Your {metric.replace('_', ' ')} is {magnitude} worsening — attention needed."
