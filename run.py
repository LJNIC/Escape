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
            file_path = Path(os.path.join(subdir, file))
            lua_file_path = file_path.with_suffix(".lua")
            file_names.append(lua_file_path)
            os.system(f"fennel --compile {file_path} > {lua_file_path}")

if run_love:
    os.system("love source/")

if delete:
    for file_name in file_names:
        os.remove(file_name)
