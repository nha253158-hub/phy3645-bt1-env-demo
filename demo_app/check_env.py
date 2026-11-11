"""In thong tin moi truong Python dang chay script nay.

Dung chung cho moi demo (venv, virtualenv, uv, pyenv, conda) de so sanh:
cung mot file, nhung moi moi truong cho ra interpreter / version / package khac nhau.
"""
import importlib.metadata as md
import platform
import sys


def pkg_version(name: str) -> str:
    try:
        return md.version(name)
    except md.PackageNotFoundError:
        return "(not installed)"


print("python      :", sys.version.split()[0])
print("executable  :", sys.executable)
print("sys.prefix  :", sys.prefix)
print("isolated env:", sys.prefix != sys.base_prefix)
print("requests    :", pkg_version("requests"))
print("os          :", platform.system(), platform.release())
