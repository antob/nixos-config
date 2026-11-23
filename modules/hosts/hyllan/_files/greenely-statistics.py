"""Copy Greenely usage (purged by the recorder) into long-term statistics, plus its cost and the plugs' cost at Nord Pool prices."""

import asyncio
import json
import os
import sys
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import websockets

URL = os.environ.get("HA_URL", "ws://127.0.0.1:8123/api/websocket")
TZ = ZoneInfo(os.environ.get("TZ_NAME", "Europe/Stockholm"))
AREA = os.environ.get("NORDPOOL_AREA", "SE3")
CURRENCY = os.environ.get("NORDPOOL_CURRENCY", "SEK")
STAT_ID = "greenely:consumption"
COST_ID = "greenely:cost"
VAT = 1.25
ADDONS = ["input_number.electricity_supplier_markup", "input_number.electricity_grid_transfer_fee", "input_number.electricity_energy_tax"]
# Energy sensor of a measuring plug -> cost statistic.
PLUGS = [
    ("sensor.upstairs_closet_hyllan_energy", "plug_cost:hyllan", "Hyllan cost"),
    ("sensor.living_room_desktob_energy", "plug_cost:desktob", "Desktob cost"),
]


def metadata(stat_id, name, unit, unit_class):
    return {"source": stat_id.split(":")[0], "statistic_id": stat_id, "name": name, "unit_of_measurement": unit,
            "unit_class": unit_class, "has_mean": False, "mean_type": 0, "has_sum": True}


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


async def known_rows(ha, stat_id):
    result = await ha.call(
        type="recorder/statistics_during_period",
        start_time="2000-01-01T00:00:00+00:00",
        statistic_ids=[stat_id],
        period="hour",
        types=["state", "sum"],
    )
    return {datetime.fromtimestamp(r["start"] / 1000, timezone.utc): float(r["state"]) for r in result.get(stat_id, [])}


async def hourly_change(ha, entity_id):
    """{utc hour: kWh used in that hour} from a sensor's own long-term statistics."""
    result = await ha.call(
        type="recorder/statistics_during_period",
        start_time="2000-01-01T00:00:00+00:00",
        statistic_ids=[entity_id],
        period="hour",
        types=["change"],
    )
    return {datetime.fromtimestamp(r["start"] / 1000, timezone.utc): float(r["change"])
            for r in result.get(entity_id, []) if r.get("change") is not None}


async def import_series(ha, meta, wanted, known, unit):
    """Import rows from the earliest new or changed one onwards, with the running sum recomputed."""
    changed = sorted(t for t, v in wanted.items() if known.get(t) != v)
    if not changed:
        print(f"{meta['statistic_id']}: no new data")
        return
    total, stats = 0.0, []
    for t in sorted(wanted):
        total += wanted[t]
        if t >= changed[0]:
            stats.append({"start": t.isoformat(), "state": wanted[t], "sum": round(total, 3)})
    if "--dry-run" in sys.argv:
        print(json.dumps(stats[:2] + stats[-2:], indent=1))
    else:
        await ha.call(type="recorder/import_statistics", metadata=meta, stats=stats)
    span = f"{stats[0]['start']} .. {stats[-1]['start']}"
    print(f"{meta['statistic_id']}: imported {len(stats)} rows ({len(changed)} new or changed), {span}, total {total:.3f} {unit}")


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

        known = await known_rows(ha, STAT_ID)
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

        await import_series(ha, metadata(STAT_ID, "Greenely consumption", "kWh", "energy"), wanted, known, "kWh")

        # Cost uses today's add-on settings; past rows keep the cost they were imported with.
        addons = sum(float(states.get(e, {}).get("state", 0) or 0) for e in ADDONS) / 100
        nordpool = (await ha.call(type="config_entries/get", domain="nordpool"))[0]["entry_id"]
        prices = {}

        oldest_price_day = datetime.now(TZ).date() - timedelta(days=58)  # Nord Pool serves about two months back

        async def day_prices(day):
            if day < oldest_price_day:
                return {}
            if day not in prices:
                try:
                    r = await ha.call(type="call_service", domain="nordpool", service="get_price_indices_for_date",
                                      service_data={"config_entry": nordpool, "date": day.isoformat(), "areas": [AREA],
                                                    "currency": CURRENCY, "resolution": 60},
                                      return_response=True)
                    prices[day] = {datetime.fromisoformat(p["start"]): (p["price"] / 1000 + addons) * VAT
                                   for p in r["response"][AREA]}
                except RuntimeError as e:
                    print(f"no Nord Pool prices for {day}: {e}")
                    prices[day] = {}
            return prices[day]

        known_cost = await known_rows(ha, COST_ID)
        rows_per_day = {}
        for t in wanted:
            rows_per_day.setdefault(local_day(t), []).append(t)
        wanted_cost = {}
        for t, kwh in wanted.items():
            if t in known_cost and known.get(t) == kwh:
                wanted_cost[t] = known_cost[t]
                continue
            day = local_day(t)
            day_price = await day_prices(day)
            if rows_per_day[day] == [midnight(day)] and day_price:
                wanted_cost[t] = round(kwh * sum(day_price.values()) / len(day_price), 4)  # daily total at the day's mean price
            elif t in day_price:
                wanted_cost[t] = round(kwh * day_price[t], 4)
        await import_series(ha, metadata(COST_ID, "Greenely cost", CURRENCY, None), wanted_cost, known_cost, CURRENCY)

        # Plugs: each hour is priced once; hours without a Nord Pool price are retried on later runs.
        for entity_id, cost_id, name in PLUGS:
            known_plug = await known_rows(ha, cost_id)
            wanted_plug = dict(known_plug)
            for t, kwh in (await hourly_change(ha, entity_id)).items():
                if t not in wanted_plug:
                    price = (await day_prices(local_day(t))).get(t)
                    if price is not None:
                        wanted_plug[t] = round(kwh * price, 4)
            await import_series(ha, metadata(cost_id, name, CURRENCY, None), wanted_plug, known_plug, CURRENCY)


if __name__ == "__main__":
    asyncio.run(main())
