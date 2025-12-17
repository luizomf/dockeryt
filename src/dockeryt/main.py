from datetime import UTC, datetime

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root() -> dict[str, str | int]:
  print("123")
  return {
    "message": "Hello, world!",
    "now": datetime.now(tz=UTC).isoformat(),
    "counter": 2,
  }
