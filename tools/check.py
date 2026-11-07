#!/usr/bin/env python3
"""Fail on any syntax, formatting, domain test or Rojo build failure."""
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
BIN=ROOT/'.tools/bin'
def run(tool,*args,**kw):
    subprocess.run([str(BIN/tool),*map(str,args)],cwd=ROOT,check=True,**kw)
for path in sorted((ROOT/'src').rglob('*.luau')):
    run('luau-compile',path,stdout=subprocess.DEVNULL)
run('stylua','--syntax','Luau','--check','src','tests')
run('luau','tests/run.luau')
subprocess.run([sys.executable, str(ROOT/'tools/test_profiles.py')],cwd=ROOT,check=True)
(ROOT/'build').mkdir(exist_ok=True)
run('rojo','build','default.project.json','-o','build/MutationGarden.rbxlx')
print('PASS: syntax, format, domain suite and place build')
