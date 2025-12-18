from datetime import UTC, datetime

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def home() -> dict[str, str | int]:
  return {
    "message": "Hello, world!",
    "now": datetime.now(tz=UTC).isoformat(),
    "counter": 1,
  }
