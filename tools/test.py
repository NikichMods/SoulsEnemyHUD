# SPDX-License-Identifier: MPL-2.0
"""Run this repository's tests; report absent executable suites honestly."""
from pathlib import Path
import subprocess, sys
root = Path(__file__).resolve().parents[1]
if sys.argv[1:]:
    raise SystemExit('Run python tools/test.py without a monorepo component selector')
tests = sorted((root / 'tests').glob('*.py'))
if not tests:
    print('NO AUTOMATED RUNTIME TEST SUITE: inspect docs/STATUS.md and migration static validation; no build/runtime acceptance claimed.')
for test in tests:
    print(test.relative_to(root), flush=True)
    subprocess.run([sys.executable, str(test)], cwd=root, check=True)
