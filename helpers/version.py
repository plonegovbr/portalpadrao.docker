
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
    parts_size = len(parts)
    if parts_size >=3:
        major, minor, patch = parts[:3]
    elif parts_size == 2:
        major = parts[0]
        minor = parts[1]
        match = re.match(r"^(?P<digits>\d{1,2})(?P<patch>.*)$", minor)
        if match:
            groups = match.groupdict()
            minor = groups["digits"]
            patch = f"0{groups['patch']}"
        else:
            patch = "0"
    return f"{major}.{minor}.{patch}"

print(extract_version(DOCKERFILE))
