# SPDX-License-Identifier: MPL-2.0
from pathlib import Path
import importlib.util
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
version = (root/'VERSION').read_text().strip()
assert f'Loaded {version};' in (root/'Scripts/main.lua').read_text(), 'Loader version must match VERSION'
node = shutil.which('node')
assert node, 'Configured Node runtime is required for the authored UI checks'
subprocess.run([node, str(root/'tests/boss_ui.test.js'), str(root/'UI/boss.js')], check=True)
spec = importlib.util.spec_from_file_location('boss_builder', root/'tools/build_boss_ui.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
try:
    builder.build(b'<html><body>unknown host data</body></html>')
    raise AssertionError('Unknown HTML accepted')
except ValueError:
    pass
host = root.parent/'.local/evidence/Asterigos-Subtitle-SoftEdges/verify-extracted/Genesis/Content/uiresources/Hud.html'
if host.exists():
    before = host.read_bytes()
    after = builder.build(before)
    start = after.index(b'\r\n<!-- SoulsEnemyHUD boss addon -->')
    end = after.index(b'</body>', start)
    assert after[:start] + after[end:] == before
    assert after.count(b'id="AsterigosSubtitleSoftEdges"') == before.count(b'id="AsterigosSubtitleSoftEdges"') == 1
    print('PASS boss builder: exact native HTML/scripts/subtitle bytes recovered after removing the single addon.')
else:
    print('SKIP local host preservation fixture unavailable; no host rendering claim.')
