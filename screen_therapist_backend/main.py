import sys, os

from app.routes import analysis, summaries
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.database import engine, Base
from app.routes import trends

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Screen Therapist Backend",
    description="Long-term trends, regression, and personalization API",
    version="1.0.0"
)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

app.include_router(summaries.router, prefix="/api/v1", tags=["Daily Summaries"])
app.include_router(trends.router,    prefix="/api/v1", tags=["Trends"])
app.include_router(analysis.router,  prefix="/api/v1/analysis", tags=["Analysis"])

@app.get("/")
def root():
    return {"message": "Screen Therapist Backend is running ✅"}

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
