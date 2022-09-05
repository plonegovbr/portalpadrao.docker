
from pathlib import Path
import re


DOCKERFILE = Path("Dockerfile").resolve()

PATTERN = r"ENV PORTAL_PADRAO=([^\n]*)\n"


def extract_version(path: Path) -> str:
    """Extract version from Dockerfile."""
    data = open(path, "r").read()
    match = re.search(PATTERN, data)
    version = match.groups()[0]
    parts = version.split(".")
    parts = parts[:3] if len(parts) >=3 else parts + ["0"]
    return f"{parts[0]}.{parts[1]}.{parts[2]}"

print(extract_version(DOCKERFILE))
