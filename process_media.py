#!/usr/bin/env python3
"""Convert source media from the Portfolio Files library into web-ready assets.

Reads every content/*.json, finds "source" paths (relative to this folder),
and writes optimized copies into dist/assets/. Records the mapping in
media_map.json for build.py. Skips work that is already up to date.

Requires only macOS built-ins: sips (images) and avconvert (video).
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIST_ASSETS = ROOT / "docs" / "assets"
MAP_PATH = ROOT / "media_map.json"

IMG_EXTS = {".jpg", ".jpeg", ".png", ".heic", ".webp"}
VID_EXTS = {".mov", ".mp4", ".m4v"}
MAX_IMG_PX = 1600
JPEG_QUALITY = "85"


def slugify(name: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", name).strip("-").lower()
    return s or "file"


def out_name(src: Path, kind: str) -> str:
    base = slugify(src.stem)
    if kind == "image":
        ext = ".png" if src.suffix.lower() == ".png" else ".jpg"
    elif kind == "video":
        ext = ".mp4"
    else:
        ext = src.suffix.lower()
    return base + ext


def needs_update(src: Path, dst: Path) -> bool:
    return not dst.exists() or src.stat().st_mtime > dst.stat().st_mtime


def process_image(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    fmt = ["-s", "format", "png"] if dst.suffix == ".png" else [
        "-s", "format", "jpeg", "-s", "formatOptions", JPEG_QUALITY]
    subprocess.run(
        ["sips", *fmt, "-Z", str(MAX_IMG_PX), str(src), "--out", str(dst)],
        check=True, capture_output=True)


def process_video(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    tmp = dst.with_suffix(".m4v")
    tmp.unlink(missing_ok=True)
    subprocess.run(
        ["avconvert", "--preset", "PresetAppleM4V720pHD",
         "--source", str(src), "--output", str(tmp)],
        check=True, capture_output=True)
    tmp.rename(dst)


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(src.read_bytes())


def image_size(path: Path):
    r = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
                       capture_output=True, text=True)
    nums = re.findall(r"pixel(?:Width|Height): (\d+)", r.stdout)
    return (int(nums[0]), int(nums[1])) if len(nums) == 2 else (None, None)


def collect_sources():
    """Yield (source_rel_path, group) pairs from all content files."""
    site = json.loads((ROOT / "content" / "site.json").read_text())
    for key in ("resume_pdf", "resume_image"):
        if site.get(key):
            yield site[key], "site"
    for f in sorted((ROOT / "content" / "projects").glob("*.json")):
        p = json.loads(f.read_text())
        if p.get("hidden"):
            continue
        if p.get("cover"):
            yield p["cover"], p["slug"]
        for b in p.get("blocks", []):
            if b.get("source"):
                yield b["source"], p["slug"]


def main():
    media_map = {}
    errors = []
    for rel, group in collect_sources():
        if rel in media_map:
            continue
        src = (ROOT / rel).resolve()
        if not src.exists():
            errors.append(f"missing source: {rel}")
            continue
        ext = src.suffix.lower()
        kind = "image" if ext in IMG_EXTS else "video" if ext in VID_EXTS else "file"
        dst = DIST_ASSETS / group / out_name(src, kind)
        if needs_update(src, dst):
            print(f"[{kind}] {rel} -> {dst.relative_to(ROOT)}")
            try:
                if kind == "image":
                    process_image(src, dst)
                elif kind == "video":
                    process_video(src, dst)
                else:
                    copy_file(src, dst)
            except subprocess.CalledProcessError as e:
                errors.append(f"failed: {rel}: {e.stderr.decode()[:200]}")
                continue
        entry = {"web": str(dst.relative_to(ROOT / "docs")), "kind": kind}
        if kind == "image":
            w, h = image_size(dst)
            entry["w"], entry["h"] = w, h
        media_map[rel] = entry
    # Render the resume PDF's page to a crisp PNG for inline display
    # (object/embed PDF viewers are unreliable, especially on mobile).
    site = json.loads((ROOT / "content" / "site.json").read_text())
    if site.get("resume_pdf"):
        src = (ROOT / site["resume_pdf"]).resolve()
        if src.exists():
            dst = DIST_ASSETS / "site" / "resume-preview.png"
            if needs_update(src, dst):
                dst.parent.mkdir(parents=True, exist_ok=True)
                print(f"[pdf-render] {site['resume_pdf']} -> {dst.relative_to(ROOT)}")
                subprocess.run(
                    ["sips", "-s", "format", "png", "--resampleWidth", "2600",
                     str(src), "--out", str(dst)],
                    check=True, capture_output=True)
            w, h = image_size(dst)
            media_map["__resume_preview__"] = {
                "web": str(dst.relative_to(ROOT / "docs")), "kind": "image",
                "w": w, "h": h}

    # Sweep assets that no longer correspond to any content entry.
    keep = {ROOT / "dist" / v["web"] for v in media_map.values()} | \
           {ROOT / "docs" / v["web"] for v in media_map.values()}
    if DIST_ASSETS.exists():
        for f in sorted(DIST_ASSETS.rglob("*")):
            if f.is_file() and f not in keep:
                print(f"[sweep] removing orphaned {f.relative_to(ROOT)}")
                f.unlink()
        for d in sorted(DIST_ASSETS.rglob("*"), reverse=True):
            if d.is_dir() and not any(d.iterdir()):
                d.rmdir()

    MAP_PATH.write_text(json.dumps(media_map, indent=1))
    print(f"\n{len(media_map)} assets ready; map written to media_map.json")
    if errors:
        print("\n".join(["", "PROBLEMS:"] + errors))
        sys.exit(1)


if __name__ == "__main__":
    main()
