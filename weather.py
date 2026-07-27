"""5AM weather-warning check. Stub until a weather API key is configured
(WEATHER_API_KEY env var) -- runs harmlessly as a no-op until then so the
scheduler can still start up cleanly.
"""
import os

import firestore_db

WEATHER_API_KEY = os.environ.get("WEATHER_API_KEY", "").strip()


async def run_weather_check_for_all_farms() -> None:
    if not WEATHER_API_KEY:
        print("[Weather] WEATHER_API_KEY not set — skipping (stub)")
        return
    farms = await firestore_db.get_all_farms()
    print(f"[Weather] running for {len(farms)} farm(s) (not yet implemented)")
