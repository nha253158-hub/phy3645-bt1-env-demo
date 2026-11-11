"""Chay ben trong container: in thong tin OS + Python de so sanh voi may host."""
import importlib.metadata as md
import platform
import socket
import sys


def os_release() -> str:
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    return line.split("=", 1)[1].strip().strip('"')
    except OSError:
        pass
    return "(unknown)"


print("Hello from inside a Docker container!")
print("hostname    :", socket.gethostname(), "(= container ID)")
print("os (userland):", os_release())
print("kernel      :", platform.system(), platform.release())
print("python      :", sys.version.split()[0], "at", sys.executable)
print("requests    :", md.version("requests"))
