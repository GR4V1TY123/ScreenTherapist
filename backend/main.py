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
            messages=[
                {
                    "role": "system",
                    "content": """
You are a behavioral analysis assistant.

Your job is to generate actionable, personalized suggestions based on user phone usage data.

Rules:
- Be specific, not generic
- Focus on behavior change
- Keep suggestions short and practical
- Avoid motivational fluff
- Base every suggestion on provided data

Output MUST be valid JSON only (no extra text).
"""
                },
                {
                    "role": "user",
                    "content": f"""
METRICS:
{input.metrics}

APPS:
{input.apps}

FLAGS:
{input.flags}

Return JSON in required format.
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