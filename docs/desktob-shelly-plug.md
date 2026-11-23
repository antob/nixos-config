# Desktob Shelly Plug (energy measurement)

Status: Phases 1 to 3 done on 2026-11-23. Phase 4 (optional) not started.

Result:
- Plug: Gen1 `SHPLG-S`, ID `4022D8831295`, 192.168.1.196 (DHCP), device name `shelly-plug-desktob`, cloud off, Power on default On, firmware v1.14.0 left as is.
- HA: area Living room, entities `*.living_room_desktob_*`; switch and restart button disabled by user.
- Energy dashboard: `sensor.living_room_desktob_energy` as "Desktob", listed after Hyllan (the devices graph still sorts bars by energy).
- Dashboard `dashboard-home`, Energy view: "Desktob" tile in Power now, "Desktob, 24 h" history graph.
- Skill docs `references/house.md` and `references/energy.md` updated (under `.agents/`, untracked).
- Cost: `greenely-statistics` on hyllan also writes `plug_cost:hyllan` and `plug_cost:desktob` (hourly energy x total price). New Cost view on `dashboard-home` with electricity price, whole-house cost and device cost. Leftover `energy` platform `*_cost` sensors (Hyllan and the four ESPHome plugs) removed.

Related change on the same day: the Greenely hourly card on the Energy view now shows 72 h to 24 h ago, with its `data_generator` reading `greenely:consumption` statistics through `hass.callWS`. ApexCharts rejects an external statistic ID as a series `entity`, so the series entity is `sensor.greenely_hourly_usage` and only satisfies the card's check.

## Goal

Add a Shelly Plug S between the wall and desktob, add it to Home Assistant, and use it to measure desktob's energy consumption. Configure it the same way as the Hyllan plug.

## Decision

Both the Hyllan plug and the desktob plug stay on stock Shelly firmware with the `shelly` integration. They do not move to ESPHome (plugs 001 to 004 use ESPHome, see `.agents/skills/home-assistant/references/esphome.md`).

Reasons:
- The Hyllan plug powers hyllan, which runs HA and the ESPHome builder. Flashing risks cutting power to the server or bricking the plug.
- Both plugs only report energy, so ESPHome adds little.
- Stock firmware needs no flash or build, and is pre-calibrated for power readings.

## What "same as Hyllan" means

Observed in the HA registry (read-only check):
- Stock firmware, `shelly` integration.
- Enabled: `sensor.*_power`, `sensor.*_energy`, `binary_sensor.*_overpowering`, `binary_sensor.*_overheating`.
- Disabled by the user: `switch.*` and `button.*_restart`, so HA can never cut power to the machine.
- Disabled by the integration: cloud, device temperature, signal strength, uptime, firmware and beta firmware update entities.
- Entity IDs follow `<area>_<device>_<entity>`, for example `sensor.upstairs_closet_hyllan_energy`.
- Listed as an individual device in the Energy dashboard.
- Firmware is never updated.

## Phase 1: Physical and network (user)

1. Plug the Shelly into the wall and power desktob through it. Check desktob's peak draw stays under the Plug S rating (12 A, about 2.8 kW at 230 V).
2. Join the plug to the home Wi-Fi through its AP (`ShellyPlugS-XXXX`, web UI at 192.168.33.1).
3. In the plug's web UI:
   - Turn off the cloud connection.
   - Set "Power on default" to On, so desktob returns after an outage.
   - Optionally set a device name.
4. Do not update the firmware.

## Phase 2: Add to HA

1. User: add the plug under Settings, Devices and Integrations, Shelly (zeroconf discovery, or manual by IP). Set the device name and area.
2. Agent, over `bin/ha ws`, after `bin/ha backup-registries <scratchpad>/registries-<date>`, touching only the new device's entities:
   - Disable `switch.*` and `button.*_restart` as the user (`disabled_by=user`).
   - Check that cloud, temperature, signal, uptime and update entities are disabled; disable any that are not.
   - Rename entity IDs to match the Hyllan pattern.

## Phase 3: Energy dashboard and docs

1. Add `sensor.<area>_<device>_energy` as an individual device in the Energy dashboard (UI, or the energy prefs WebSocket call, see `references/energy.md`).
2. Add a "Desktob plug" note to `.agents/skills/home-assistant/references/house.md` and mention it in `references/energy.md`.
3. Commit the HA config dir if anything in it changed.

## Phase 4: Optional

- DHCP reservation for the plug. Plugs have no fixed addresses yet and that work is paused.
- Check whether `modules/hosts/desktob/wake-guard.nix` is relevant to the plug (not reviewed).

## Notes

- No Nix changes and no host switch are needed.
- Hardware revision of the plug is unknown, which only matters if ESPHome is reconsidered later.
