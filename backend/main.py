from dotenv import load_dotenv
import os
import json
from pydantic import BaseModel
from typing import List, Dict
from fastapi import FastAPI
from groq import Groq
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

class Input(BaseModel):
    query: str
    metrics: Dict[str, str]
    apps: List[Dict[str, str]]
    flags: List[str]

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/suggestions")
def get_suggestions(input: Input):
    try:
        response = client.chat.completions.create(
            model="openai/gpt-oss-20b",
            messages = [
    {
        "role": "system",
        "content": """
You are a behavioral analysis assistant.

Your job is to generate actionable, personalized suggestions based on user phone usage data and user input.

You MUST:
- Analyze metrics, apps, and flags
- Incorporate user's personal input (feelings, goals, concerns)
- Suggest behavior changes AND relevant alternative activities

Rules:
- Be specific, not generic
- Keep suggestions short and practical
- Avoid motivational or vague advice
- Every suggestion must be based on provided data
- Prefer high-impact changes over small optimizations

Output MUST be valid JSON only (no extra text).
"""
    },
    {
        "role": "user",
        "content": f"""
USER INPUT:
{input.query}

METRICS (Including ML Regression & Predictions):
{input.metrics}

SPECIFIC APP USAGE (Today):
{input.apps}

BEHAVIORAL FLAGS:
{input.flags}

---

Return output in this exact JSON format:

{{
  "summary": "1-2 line summary of user behavior + concern",
  "suggestions": [
    {{
      "title": "short title",
      "reason": "why this suggestion is given (Must reference specific apps from the App Usage list and mention specific minutes spent)",
      "action": "clear actionable step (e.g. 'Set a timer for 15 mins before opening Instagram')",
      "priority": "low | medium | high"
    }}
  ],

  "alternative_activities": [
    {{
      "based_on": "Specific app or behavior (e.g., spending 90 mins on TikTok)",
      "suggestion": "offline or healthier alternative (e.g., Read a physical book, go for a 10 min walk)",
      "type": "physical | mental | social"
    }}
  ]
}}

Constraints:
- Max 5 suggestions
- At least 2 alternative activities
- Prioritize high-impact behavioral fixes
- If user input expresses concern (e.g., addiction, distraction), address it directly
- CRITICAL: Tie suggestions directly to specific apps in the user's App Usage list. State the exact name of the app and the amount of time they spent on it. Do not give generic advice like "reduce social media". Instead say "Reduce Instagram usage which took 2 hours today".
- CRITICAL: Utilize the Mathematical ML predictions (e.g., "Predicted tomorrow's screen time is 5 hours, let's break that trajectory by doing X").

Return ONLY JSON.
"""
    }
]
        )

        content = response.choices[0].message.content
        parsed = json.loads(content)

        return parsed

    except Exception as e:
        return {
            "error": str(e),
            "fallback": {
                "summary": "Unable to generate suggestions",
                "suggestions": []
            }
        }