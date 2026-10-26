# SPDX-License-Identifier: MPL-2.0
"""Append authored UI to an exact local host HTML. Never commit the output/host input."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
KNOWN = {
    'f3edde51ec5d285ef242968a66f97f8da207cf5ec65b3c229e573f938937c87b',  # Stock Steam1.09.
    'd68d844ce6be1527ba4b4341d75e4723458337a32450a667b5a08072e24ac4a5',  # Accepted subtitle CSS.
}


def build(before: bytes) -> bytes:
    digest = hashlib.sha256(before).hexdigest()
    if digest not in KNOWN:
        raise ValueError('Unverified Hud.html input: ' + digest)
    if before.count(b'</body>') != 1 or b'SoulsEnemyHUDBossDamage' in before:
        raise ValueError('Unexpected HTML structure or existing addon')
    css = (ROOT / 'UI/boss.css').read_bytes()
    js = (ROOT / 'UI/boss.js').read_bytes()
    addon = b'\r\n<!-- SoulsEnemyHUD boss addon -->\r\n<style>\r\n' + css + b'\r\n</style>\r\n<script>\r\n' + js + b'\r\n</script>\r\n'
    after = before.replace(b'</body>', addon + b'</body>', 1)
    assert after.replace(addon, b'', 1) == before  # Including accepted subtitle patch and every native script.
    return after


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('stage', type=Path)
    args = parser.parse_args()
    output = args.stage / 'Genesis/Content/uiresources/Hud.html'
    if output.exists():
        raise SystemExit('Refusing to overwrite staged output')
    before = args.input.read_bytes()
    after = build(before)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(after)
    (args.stage.parent / (args.stage.name + '-build.json')).write_text(json.dumps({
        'input_sha256': hashlib.sha256(before).hexdigest(),
        'output_sha256': hashlib.sha256(after).hexdigest(),
        'version': (ROOT / 'VERSION').read_text().strip(),
        'preservation': 'Remove one appended addon to recover exact input, including subtitle patch',
    }, indent=2), encoding='utf-8')
    print(output)
