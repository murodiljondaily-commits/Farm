"""Scheduled jobs: the 8PM daily digest and the 5AM weather-warning check.
Runs in-process via APScheduler rather than needing separate cron
infrastructure -- Railway doesn't run cron for a plain FastAPI service, and
an in-process scheduler is the simplest thing that works for a farm-count
this small. Both jobs are pinned to Asia/Tashkent (UZ has no DST, fixed
UTC+5) so "8PM"/"5AM" mean what a farmer expects regardless of what
timezone the container itself runs in.
"""
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

TASHKENT = "Asia/Tashkent"

_scheduler = AsyncIOScheduler(timezone=TASHKENT)


def start_scheduler() -> None:
    if _scheduler.running:
        return

    # Imported lazily so a bug in digest/weather job code can't prevent the
    # whole app from starting up -- scheduler wiring itself must never be
    # the reason /chat etc. go down.
    from digest import run_daily_digest_for_all_farms
    from weather import run_weather_check_for_all_farms

    _scheduler.add_job(
        run_daily_digest_for_all_farms,
        CronTrigger(hour=20, minute=0, timezone=TASHKENT),
        id="daily_digest",
        replace_existing=True,
    )
    _scheduler.add_job(
        run_weather_check_for_all_farms,
        CronTrigger(hour=5, minute=0, timezone=TASHKENT),
        id="weather_check",
        replace_existing=True,
    )
    _scheduler.start()
    print("[Scheduler] started: daily_digest @ 20:00, weather_check @ 05:00 (Asia/Tashkent)")


def schedule_one_time(func, run_date, *, job_id: str, args: tuple = ()) -> None:
    """Used by the weather job to fire a specific farm's warning exactly
    1 hour before the predicted onset, rather than waiting for the next
    cron tick."""
    _scheduler.add_job(
        func,
        "date",
        run_date=run_date,
        id=job_id,
        args=args,
        replace_existing=True,
        misfire_grace_time=600,
    )
