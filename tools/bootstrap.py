#!/usr/bin/env python3
"""Pinned Linux x86_64 tools; TLS plus pinned archive digest verification."""
import hashlib
import io
import os
from pathlib import Path
import platform
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = [
    ('rojo', 'https://github.com/rojo-rbx/rojo/releases/download/v7.6.1/rojo-7.6.1-linux-x86_64.zip', 'a9542a713036897fdbd0173e7a105ea409658333133c949025fcb6f1a7ca909d'),
    ('luau', 'https://github.com/luau-lang/luau/releases/download/0.699/luau-ubuntu.zip', '4169f04aa66c8f5039d5cb2257aab9e81674ec152a8d84bda96c12cdb9fa973a'),
    ('stylua', 'https://github.com/JohnnyMorganz/StyLua/releases/download/v2.1.0/stylua-linux-x86_64.zip', '66a8e8d68003848d23bd7dfca95e3d0e7b96bd19658879b1f8b39d992f3be331'),
]
assert platform.system() == 'Linux' and platform.machine() == 'x86_64', 'Use vendor releases for your platform'
dest = ROOT / '.tools/bin'
dest.mkdir(parents=True, exist_ok=True)
for name, url, expected in TOOLS:
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / 'download.zip'
        subprocess.run(['curl', '-fsSL', '--retry', '2', '--max-time', '120', url, '-o', str(archive)], check=True)
        data = archive.read_bytes()
        assert hashlib.sha256(data).hexdigest() == expected, f'Checksum mismatch: {name}'
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for entry in z.infolist():
                if entry.is_dir():
                    continue
                path = Path(entry.filename)
                assert len(path.parts) == 1, 'Unexpected archive layout'
                target = dest / path.name
                target.write_bytes(z.read(entry))
                target.chmod(0o755)
    print('Installed verified archive:', name)
