from fastapi import FastAPI

app = FastAPI(title="__NAME__")


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
