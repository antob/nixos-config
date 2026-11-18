"""Copy Greenely usage from sensor attributes (purged by the recorder) into long-term statistics."""

import asyncio
import json
import os
import sys
from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

import websockets

URL = os.environ.get("HA_URL", "ws://127.0.0.1:8123/api/websocket")
TZ = ZoneInfo(os.environ.get("TZ_NAME", "Europe/Stockholm"))
STAT_ID = "greenely:consumption"
METADATA = {
    "source": "greenely",
    "statistic_id": STAT_ID,
    "name": "Greenely consumption",
    "unit_of_measurement": "kWh",
    "unit_class": "energy",
    "has_mean": False,
    "mean_type": 0,
    "has_sum": True,
}


def read_token():
    path = os.environ.get("HA_TOKEN_FILE") or os.path.join(os.environ["CREDENTIALS_DIRECTORY"], "token")
    with open(path) as f:
        return f.read().strip()


class HA:
    def __init__(self, ws):
        self.ws, self.n = ws, 0

    async def call(self, **msg):
        self.n += 1
        await self.ws.send(json.dumps({"id": self.n, **msg}))
        while True:
            r = json.loads(await self.ws.recv())
            if r.get("id") == self.n and r["type"] == "result":
                if not r["success"]:
                    raise RuntimeError(f"{msg['type']}: {r['error']}")
                return r["result"]


def hourly_rows(data):
    """Greenely 'YYYY-MM-DD HH:MM' local times -> {utc hour: kWh}; a repeated hour (DST end) gets fold=1."""
    rows, seen = {}, set()
    for d in data:
        if not d.get("usage"):
            continue
        local = datetime.strptime(d["localtime"], "%Y-%m-%d %H:%M")
        fold = 1 if local in seen else 0
        seen.add(local)
        rows[local.replace(tzinfo=TZ, fold=fold).astimezone(timezone.utc)] = float(d["usage"])
    return rows


def local_day(ts):
    return ts.astimezone(TZ).date()


def midnight(day):
    return datetime.combine(day, datetime.min.time(), TZ).astimezone(timezone.utc)


async def main():
    async with websockets.connect(URL, max_size=None) as ws:
        await ws.recv()
        await ws.send(json.dumps({"type": "auth", "access_token": read_token()}))
        if json.loads(await ws.recv())["type"] != "auth_ok":
            sys.exit("authentication failed")
        ha = HA(ws)

        states = {s["entity_id"]: s for s in await ha.call(type="get_states")}
        hourly = states.get("sensor.greenely_hourly_usage", {}).get("attributes", {}).get("data") or []
        daily = states.get("sensor.greenely_daily_usage", {}).get("attributes", {}).get("data") or []

        existing = await ha.call(
            type="recorder/statistics_during_period",
            start_time="2000-01-01T00:00:00+00:00",
            statistic_ids=[STAT_ID],
            period="hour",
            types=["state", "sum"],
        )
        known = {
            datetime.fromtimestamp(r["start"] / 1000, timezone.utc): float(r["state"])
            for r in existing.get(STAT_ID, [])
        }

        wanted = dict(known)
        new_hourly = hourly_rows(hourly)
        hourly_days = {local_day(t) for t in new_hourly}
        for t in list(wanted):
            if local_day(t) in hourly_days:
                del wanted[t]  # hourly data replaces a backfilled daily total for the same day
        wanted.update(new_hourly)

        # Days without hourly data (the initial backfill) get their daily total as one row at local midnight.
        days_with_data = {local_day(t) for t in wanted}
        for d in daily:
            day = date.fromisoformat(d["localtime"])
            if d.get("usage") and day not in days_with_data:
                wanted[midnight(day)] = float(d["usage"])

        changed = sorted(t for t, v in wanted.items() if known.get(t) != v)
        if not changed:
            print("no new data")
            return

        total, stats = 0.0, []
        for t in sorted(wanted):
            total += wanted[t]
            if t >= changed[0]:
                stats.append({"start": t.isoformat(), "state": wanted[t], "sum": round(total, 3)})
        if "--dry-run" in sys.argv:
            print(json.dumps(stats[:3] + stats[-3:], indent=1))
        else:
            await ha.call(type="recorder/import_statistics", metadata=METADATA, stats=stats)
        span = f"{stats[0]['start']} .. {stats[-1]['start']}"
        print(f"imported {len(stats)} rows ({len(changed)} new or changed), {span}, total {total:.3f} kWh")


if __name__ == "__main__":
    asyncio.run(main())
