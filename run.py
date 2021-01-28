#!/usr/bin/python3
from pathlib import Path
import sys
import os

run_love = True
delete = True

if "-s" in sys.argv:
    delete = False

if "-l" in sys.argv:
    run_love = False

file_names = []
for subdir, dirs, files in os.walk("."):
    for file in files:
        if ".fnl" in file:
            file_path = Path(file)
            file_names.append(file_path.with_suffix(".lua"))
            file_name = file_path.stem
            os.system(f"fennel --compile {file} > {file_name}.lua")

if run_love:
    os.system("love .")

if delete:
    for file_name in file_names:
        os.remove(file_name)
