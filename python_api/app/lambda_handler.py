from __future__ import annotations

from mangum import Mangum

from .main import app

# Handler AWS Lambda (API Gateway HTTP API -> FastAPI).
# Mantem os mesmos endpoints ja usados no app.
handler = Mangum(app, lifespan="off")
