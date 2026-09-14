"""Check the exact portable archive and shared PCK without extracting files."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parent.parent
archive = root / 'build/TaiwanFighter-0.2.0-Windows.zip'
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None, 'ZIP CRC validation failed'
    entries = {}
    for name in z.namelist():
        payload = z.read(name)
        assert payload == (root / 'build/windows' / name).read_bytes(), name
        entries[name] = {'bytes': len(payload), 'sha256': hashlib.sha256(payload).hexdigest()}
assert (root / 'build/windows/TaiwanFighter.pck').read_bytes() == (root / 'build/web/index.pck').read_bytes()
report = {'archive_bytes': archive.stat().st_size, 'zip_crc_passed': True,
          'all_entries_match_windows_folder': True, 'web_windows_pck_identical': True, 'entries': entries}
(root / 'artifacts/benchmark/release-integrity.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
