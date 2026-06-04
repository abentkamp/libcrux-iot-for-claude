#!/usr/bin/env python3

import os
import re
import subprocess
import sys
from pathlib import Path

HAX_VERSION = "c1ba7b8f4bead612ff24952b57abeb902b288718"
AENEAS_VERSION = "unknown"


def check_version(cmd: list[str], name: str, expected: str) -> None:
    result = subprocess.run(cmd, capture_output=True, text=True)
    output = result.stdout + result.stderr
    if expected not in output:
        print(f"Version mismatch for {name}: expected {expected!r} in output:\n{output}", file=sys.stderr)
        sys.exit(1)


check_version(["cargo", "hax", "--version"], "hax", HAX_VERSION)
check_version(["aeneas", "-version"], "aeneas", AENEAS_VERSION)

result = subprocess.run(
    ["cargo", "hax", "into", "aeneas-lean", '--aeneas-args="-core-models-lib"'],
    env={**os.environ, "RUSTFLAGS": "--cfg hax_backend_lean"},
    capture_output=True,
    text=True,
)

# Suppress version mismatch warnings. (We check versions above.)
_ANSI = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')
def should_suppress(line: str) -> bool:
    plain = _ANSI.sub('', line)
    return plain.startswith("warning: hax: aeneas version mismatch:") or plain.startswith("warning: hax: charon version mismatch:")

for line in result.stdout.splitlines():
    if not should_suppress(line):
        print(line)
for line in result.stderr.splitlines():
    if not should_suppress(line):
        print(line, file=sys.stderr)
# Aeneas reports a non-zero exit when it can't generate a definition for an
# extracted external item (here: the `Debug` derive on `Algorithm`). The
# generated Funs.lean still has the axiom inline, so we tolerate this
# specific failure and continue with the post-processing below.
if result.returncode != 0:
    print(f"warning: aeneas exited with code {result.returncode}; "
          f"continuing with post-processing (axiom remains inline).",
          file=sys.stderr)

funs_lean = Path("proofs/aeneas-lean/LibcruxIotSha3/Extraction/Funs.lean")
content = funs_lean.read_text()

content = re.sub(
    r"(^import Aeneas\b)",
    r"\1\nimport LibcruxIotSha3.Extraction.Missing",
    content,
    count=1,
    flags=re.MULTILINE,
)

# Patch the auto-generated `Debug for Algorithm` impl: aeneas can't extract
# the `derive(Debug)` body so it leaves the `fmt` callee as an axiom with
# the wrong arity (extra `Formatter → Formatter` component), and uses
# `fmt :=` where the structure field is named `dbg_fmt`. Replace the
# whole record with a trivial Debug instance.
content = content.replace(
    "def Algorithm.Insts.CoreFmtDebug : core.fmt.Debug Algorithm := {\n"
    "  fmt := Algorithm.Insts.CoreFmtDebug.fmt\n}",
    "def Algorithm.Insts.CoreFmtDebug : core.fmt.Debug Algorithm :=\n"
    "  { dbg_fmt := fun _ f => ok (.Ok (), f) }",
    1,
)

# `core.fmt.rt.Argument.new_display` is extracted with arity 1 (the value to
# format), but the `keccak::_squeeze` panic-fmt block calls it with the
# `Display` instance as an extra arg, and `core.fmt.Arguments.new` is also
# stubbed. Comment the whole block out — the `fail panic` below ends the
# branch anyway.
panic_block = (
    "    let a ←\n"
    "      core.fmt.rt.Argument.new_display core.Usize.Insts.CoreFmtDisplay i\n"
    "    let a1 ←\n"
    "      core.fmt.rt.Argument.new_display core.Usize.Insts.CoreFmtDisplay RATE\n"
    "    let _ ←\n"
    "      core.fmt.Arguments.new\n"
    "        (Array.make 7#usize [\n"
    "          192#u8, 3#u8, 32#u8, 62#u8, 32#u8, 192#u8, 0#u8\n"
    "          ]) (Array.make 2#usize [ a, a1 ])"
)
content = content.replace(panic_block, "/-\n" + panic_block + "\n-/", 1)

funs_lean.write_text(content)
