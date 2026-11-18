"""Read the journal of the units the agent is allowed to see (run via sudo)."""

import argparse
import json
import os
import sys

JOURNALCTL = "@journalctl@"
UNITS = json.loads('@units@')
PRIORITIES = ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"]
OUTPUTS = ["short-iso", "short-precise", "cat", "json", "with-unit"]


def unit_name(name):
    full = name if "." in name else f"{name}.service"
    if full not in UNITS:
        sys.exit(f"agent-logs: {name} is not allowed; allowed units: {', '.join(UNITS)}")
    return full


parser = argparse.ArgumentParser(prog="agent-logs", description=f"Allowed units: {', '.join(UNITS)}")
parser.add_argument("units", nargs="*", help="units to show (without arguments: list allowed units)")
parser.add_argument("-n", "--lines", type=int, default=200)
parser.add_argument("-S", "--since")
parser.add_argument("-U", "--until")
parser.add_argument("-g", "--grep")
parser.add_argument("-p", "--priority", choices=PRIORITIES)
parser.add_argument("-o", "--output", choices=OUTPUTS, default="short-iso")
parser.add_argument("-b", "--boot", type=int, help="boot offset, e.g. 0 or -1")
parser.add_argument("-r", "--reverse", action="store_true")
args = parser.parse_args()

if not args.units:
    print("\n".join(UNITS))
    sys.exit(0)

# Values are passed as --opt=value so they can never be read as further options.
cmd = [JOURNALCTL, "--no-pager", f"--lines={max(1, min(args.lines, 20000))}", f"--output={args.output}"]
cmd += [f"--unit={unit_name(u)}" for u in args.units]
for opt in ("since", "until", "grep", "priority"):
    if getattr(args, opt) is not None:
        cmd.append(f"--{opt}={getattr(args, opt)}")
if args.boot is not None:
    cmd.append(f"--boot={args.boot}")
if args.reverse:
    cmd.append("--reverse")
os.execv(JOURNALCTL, cmd)
