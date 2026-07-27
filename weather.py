"""5AM weather-warning check: scans each farm's hourly forecast for the day,
and if heavy rain or heavy wind is predicted, schedules a push exactly 1
hour before it's expected to start. Uses Google's Geocoding + Weather APIs
(Maps Platform) -- confirmed live with a real key: geocoding turns the
farm's free-text location ("Andijon, Xo'jaobod") into coordinates once
(cached on the farm doc after first success, since a farm's location
essentially never changes), and the Weather API's hourly forecast accepts
those coordinates directly, no separate provider needed.
"""
import os
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

import httpx

import firestore_db
import push
from scheduler import schedule_one_time

WEATHER_API_KEY = os.environ.get("WEATHER_API_KEY", "").strip()

GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"
FORECAST_URL = "https://weather.googleapis.com/v1/forecast/hours:lookup"

# Standard meteorological "heavy rain" threshold (mm in the hour) and a
# reasonable severe-wind threshold for livestock safety (sustained km/h or
# gust km/h). Tunable -- these are defaults, not measured/requested values.
HEAVY_RAIN_MM = 10.0
HEAVY_WIND_KMH = 40.0
HEAVY_GUST_KMH = 60.0


async def geocode_location(location: str) -> Optional[Tuple[float, float]]:
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(GEOCODE_URL, params={"address": location, "key": WEATHER_API_KEY})
        data = resp.json()
        if data.get("status") != "OK" or not data.get("results"):
            print(f"[Weather] geocode failed for {location!r}: {data.get('status')}")
            return None
        loc = data["results"][0]["geometry"]["location"]
        return loc["lat"], loc["lng"]


async def _get_farm_coords(farm: Dict) -> Optional[Tuple[float, float]]:
    lat, lng = farm.get("location_lat"), farm.get("location_lng")
    if lat is not None and lng is not None:
        return lat, lng
    location_text = farm.get("location")
    if not location_text:
        return None
    coords = await geocode_location(location_text)
    if coords is None:
        return None
    lat, lng = coords
    # Cache so every future 5AM run for this farm skips geocoding entirely.
    await firestore_db.save_farm({
        "farm_id": farm["farm_id"], "location_lat": lat, "location_lng": lng,
    })
    return lat, lng


async def get_hourly_forecast(lat: float, lng: float, hours: int = 24) -> List[Dict]:
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(FORECAST_URL, params={
            "key": WEATHER_API_KEY,
            "location.latitude": lat,
            "location.longitude": lng,
            "hours": hours,
            "pageSize": hours,
        })
        data = resp.json()
        return data.get("forecastHours", [])


def find_first_warning(forecast_hours: List[Dict]) -> Optional[Dict]:
    """Returns the first hour (chronologically) that crosses either
    threshold, or None. Only the first is used -- one warning per day is
    the spec ("notify 1 hour before"), not one per qualifying hour."""
    for hour in forecast_hours:
        qpf = (hour.get("precipitation", {}).get("qpf", {}) or {}).get("quantity", 0) or 0
        wind_speed = (hour.get("wind", {}).get("speed", {}) or {}).get("value", 0) or 0
        wind_gust = (hour.get("wind", {}).get("gust", {}) or {}).get("value", 0) or 0

        start_time = hour.get("interval", {}).get("startTime")
        if not start_time:
            continue

        if qpf >= HEAVY_RAIN_MM:
            return {"type": "rain", "start_time": start_time}
        if wind_speed >= HEAVY_WIND_KMH or wind_gust >= HEAVY_GUST_KMH:
            return {"type": "wind", "start_time": start_time}
    return None


async def _send_scheduled_warning(farm_id: str, warning_type: str, time_str: str) -> None:
    key = "weather_rain" if warning_type == "rain" else "weather_wind"
    sent = await push.send_localized_to_farm(
        farm_id,
        title_key=f"{key}_title",
        body_key=f"{key}_body",
        body_vars={"time": time_str},
    )
    print(f"[Weather] {farm_id}: sent {warning_type} warning to {sent} device(s)")


async def run_weather_check_for_all_farms() -> None:
    if not WEATHER_API_KEY:
        print("[Weather] WEATHER_API_KEY not set — skipping")
        return

    farms = await firestore_db.get_all_farms()
    print(f"[Weather] checking {len(farms)} farm(s)")
    for farm in farms:
        farm_id = farm.get("farm_id")
        if not farm_id:
            continue
        try:
            coords = await _get_farm_coords(farm)
            if coords is None:
                print(f"[Weather] {farm_id}: no usable location, skipped")
                continue
            forecast = await get_hourly_forecast(*coords)
            warning = find_first_warning(forecast)
            if warning is None:
                print(f"[Weather] {farm_id}: no warnings today")
                continue

            onset = datetime.fromisoformat(warning["start_time"].replace("Z", "+00:00"))
            fire_at = onset - timedelta(hours=1)
            now = datetime.now(timezone.utc)
            if fire_at <= now:
                # Onset is under an hour away (or already passed) by the time
                # the 5AM scan ran -- send immediately rather than schedule
                # a job in the past, which APScheduler would just skip.
                await _send_scheduled_warning(
                    farm_id, warning["type"], onset.strftime("%H:%M")
                )
            else:
                schedule_one_time(
                    _send_scheduled_warning,
                    fire_at,
                    job_id=f"weather_warn_{farm_id}",
                    args=(farm_id, warning["type"], onset.strftime("%H:%M")),
                )
                print(f"[Weather] {farm_id}: {warning['type']} warning scheduled for {fire_at.isoformat()}")
        except Exception as exc:
            print(f"[Weather] {farm_id}: ERROR {exc}")
