
from pathlib import Path
import re


DOCKERFILE = Path("Dockerfile").resolve()

PATTERN = r"ENV PORTAL_PADRAO=([^\n]*)\n"


def extract_version(path: Path) -> str:
    """Extract version from Dockerfile."""
    data = open(path, "r").read()
    match = re.search(PATTERN, data)
    version = match.groups()[0]
    return version

print(extract_version(DOCKERFILE))
