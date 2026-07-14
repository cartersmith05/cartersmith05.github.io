#!/usr/bin/env python3
"""Static site generator for Carter Smith's portfolio.

Reads content/*.json + media_map.json (produced by process_media.py) and
writes the finished site into dist/. No dependencies beyond the stdlib.

    python3 process_media.py   # once, or whenever source media changes
    python3 build.py           # regenerate HTML
"""
import html
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIST = ROOT / "docs"

SITE = json.loads((ROOT / "content" / "site.json").read_text())
MEDIA = json.loads((ROOT / "media_map.json").read_text())
PROJECTS = sorted(
    (p for p in (json.loads(f.read_text())
                 for f in (ROOT / "content" / "projects").glob("*.json"))
     if not p.get("hidden")),
    key=lambda p: p["order"])

e = html.escape


def asset(rel_source: str, depth: int) -> str:
    return "../" * depth + MEDIA[rel_source]["web"]


def page(title: str, description: str, body: str, depth: int, active: str = "") -> str:
    r = "../" * depth
    nav_work = ' class="active"' if active == "work" else ""
    nav_resume = ' class="active"' if active == "resume" else ""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(title)}</title>
<meta name="description" content="{e(description)}">
<link rel="stylesheet" href="{r}style.css">
<link rel="icon" href="{r}favicon.svg" type="image/svg+xml">
</head>
<body>
<header class="site-header">
  <a class="wordmark" href="{r}index.html">{e(SITE['name'])}</a>
  <nav>
    <a href="{r}work/index.html"{nav_work}>Work</a>
    <a href="{r}resume/index.html"{nav_resume}>Resume</a>
  </nav>
</header>
<main>
{body}
</main>
<footer class="site-footer">
  <p>© 2026 {e(SITE['name'])}</p>
  <p>
    <a href="mailto:{e(SITE['email'])}">{e(SITE['email'])}</a> ·
    <a href="{e(SITE['linkedin'])}" target="_blank" rel="noopener">LinkedIn</a>
  </p>
</footer>
<div class="lightbox" id="lightbox" hidden><img alt=""></div>
<script src="{r}main.js"></script>
</body>
</html>"""


def project_card(p: dict, depth: int) -> str:
    cover = asset(p["cover"], depth) if p.get("cover") in MEDIA else ""
    img = f'<img src="{cover}" alt="{e(p["title"])}" loading="lazy">' if cover else ""
    return f"""<a class="card" href="{'../' * depth}work/{p['slug']}/index.html">
  <div class="card-media">{img}</div>
  <div class="card-body">
    <span class="card-year">{p['year']}</span>
    <h3>{e(p['title'])}</h3>
    <p>{e(p['tagline'])}</p>
  </div>
</a>"""


def render_blocks(p: dict, depth: int) -> str:
    out = []
    for b in p["blocks"]:
        t = b["type"]
        if t == "text":
            if b.get("heading"):
                out.append(f"<h2>{e(b['heading'])}</h2>")
            out.extend(f"<p>{e(par)}</p>" for par in b["body"])
        elif t == "image" and b["source"] in MEDIA:
            m = MEDIA[b["source"]]
            dims = f' width="{m["w"]}" height="{m["h"]}"' if m.get("w") else ""
            out.append(
                f'<figure><img src="{asset(b["source"], depth)}" '
                f'alt="{e(b["caption"])}"{dims} loading="lazy">'
                f"<figcaption>{e(b['caption'])}</figcaption></figure>")
        elif t == "video" and b["source"] in MEDIA:
            out.append(
                f'<figure><video src="{asset(b["source"], depth)}" controls '
                f'playsinline preload="metadata"></video>'
                f"<figcaption>{e(b['caption'])}</figcaption></figure>")
        elif t == "file" and b["source"] in MEDIA:
            out.append(
                f'<p class="file-link"><a href="{asset(b["source"], depth)}" '
                f'download>{e(b["label"])} ↓</a></p>')
    return "\n".join(out)


def build_home():
    cards = "\n".join(project_card(p, 0)
                      for s in SITE["featured"]
                      for p in PROJECTS if p["slug"] == s)
    body = f"""<section class="hero">
  <h1>{e(SITE['name'])}</h1>
  <p class="hero-meta">{e(SITE['subtitle'])} · 📍 {e(SITE['location'])}</p>
  <p class="hero-tagline">{e(SITE['tagline'])}</p>
  <p class="hero-bio">{e(SITE['bio'])}</p>
</section>
<section>
  <div class="section-head"><h2>Projects</h2><a class="more" href="work/index.html">View all →</a></div>
  <div class="card-grid">
{cards}
  </div>
</section>"""
    write("index.html", page(f"{SITE['name']} — Mechanical Engineering Portfolio",
                             SITE["tagline"], body, 0))


def build_work():
    cards = "\n".join(project_card(p, 1) for p in PROJECTS)
    body = f"""<section class="hero">
  <h1>My Work</h1>
  <p class="hero-tagline">{e(SITE['work_intro'])}</p>
</section>
<section>
  <div class="card-grid">
{cards}
  </div>
</section>"""
    write("work/index.html", page(f"Work — {SITE['name']}", SITE["work_intro"],
                                  body, 1, active="work"))


def build_projects():
    for i, p in enumerate(PROJECTS):
        prev_p = PROJECTS[i - 1] if i > 0 else None
        next_p = PROJECTS[i + 1] if i < len(PROJECTS) - 1 else None
        nav = []
        if prev_p:
            nav.append(f'<a class="pn prev" href="../{prev_p["slug"]}/index.html">‹ {e(prev_p["title"])}</a>')
        if next_p:
            nav.append(f'<a class="pn next" href="../{next_p["slug"]}/index.html">{e(next_p["title"])} ›</a>')
        body = f"""<article class="project">
<p class="crumb"><a href="../index.html">‹ All Projects</a></p>
<h1>{e(p['title'])}</h1>
<p class="project-meta">🗓️ {p['year']}</p>
<p class="lede">{e(p['lede'])}</p>
{render_blocks(p, 2)}
<nav class="prev-next">{''.join(nav)}</nav>
</article>"""
        write(f"work/{p['slug']}/index.html",
              page(f"{p['title']} — {SITE['name']}", p["lede"], body, 2, active="work"))


def build_resume():
    if SITE.get("resume_pdf") and SITE["resume_pdf"] in MEDIA and "__resume_preview__" in MEDIA:
        pdf = asset(SITE["resume_pdf"], 1)
        preview = MEDIA["__resume_preview__"]
        viewer = f"""<figure class="resume-img"><img src="{'../' + preview['web']}" \
alt="Resume of {e(SITE['name'])}" width="{preview['w']}" height="{preview['h']}"></figure>
<p class="file-link"><a href="{pdf}" download>Download resume (PDF) ↓</a></p>"""
    else:
        src = asset(SITE["resume_image"], 1)
        viewer = f'<figure class="resume-img"><img src="{src}" alt="Resume of {e(SITE["name"])}"></figure>'
    body = f"""<section class="hero"><h1>Resume</h1></section>
{viewer}"""
    write("resume/index.html", page(f"Resume — {SITE['name']}", f"Resume of {SITE['name']}",
                                    body, 1, active="resume"))


def write(rel: str, content: str):
    out = DIST / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content)


def main():
    DIST.mkdir(exist_ok=True)
    for f in ("style.css", "main.js", "favicon.svg"):
        shutil.copyfile(ROOT / "static" / f, DIST / f)
    build_home()
    build_work()
    build_projects()
    build_resume()
    print(f"built {len(PROJECTS)} project pages + home, work, resume -> docs/")


if __name__ == "__main__":
    main()
