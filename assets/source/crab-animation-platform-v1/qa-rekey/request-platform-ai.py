"""Request one unchanged Framecraft HTTP matte; no image processing here."""
import hashlib
import json
from pathlib import Path
import sys
import time

import httpx

source = Path(sys.argv[1])
output = Path(sys.argv[2])
resolution = int(sys.argv[3])
base_url = "http://127.0.0.1:8766"
options = {
    "mode": "birefnet",
    "device": "cpu",
    "resolution": str(resolution),
    "birefnet_variant": "lite",
    "key_color": "#426d6f",
    "spill": "0",
}
started = time.monotonic()
with httpx.Client(timeout=600, trust_env=False) as client:
    with source.open("rb") as stream:
        response = client.post(base_url + "/api/matte", data=options, files={"image": (source.name, stream, "image/png")})
    elapsed = time.monotonic() - started
    response.raise_for_status()
    if not response.headers.get("content-type", "").startswith("image/png"):
        raise RuntimeError("Framecraft did not return a PNG")
    output.write_bytes(response.content)
    health = client.get(base_url + "/api/health").json()
record = {
    "input": source.name,
    "inputSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
    "output": output.name,
    "outputSha256": hashlib.sha256(response.content).hexdigest(),
    "endpoint": "/api/matte",
    "request": options,
    "httpStatus": response.status_code,
    "responseHeaders": dict(response.headers),
    "elapsedSeconds": round(elapsed, 3),
    "healthAfter": health,
}
output.with_suffix(".request.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"output": str(output), "elapsedSeconds": round(elapsed, 3), "mode": response.headers.get("x-matte-mode"), "device": response.headers.get("x-matte-device")}))
