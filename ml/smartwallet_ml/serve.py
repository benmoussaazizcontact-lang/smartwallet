"""Process entrypoint. The platform supplies PORT; no secret is read from the image."""

import os

import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "smartwallet_ml.api:app",
        host="0.0.0.0",
        port=int(os.environ.get("PORT", "8080")),
        log_level="info",
        access_log=True,
    )
