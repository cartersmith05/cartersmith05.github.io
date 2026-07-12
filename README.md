# Carter Smith — Portfolio Site

A dependency-free static portfolio site. All content lives in JSON files; two
small Python scripts (macOS built-ins only, no npm/pip installs) turn the raw
photos and videos in `Portfolio Files/` into the finished site in `docs/`.

## Layout

```
portfolio-site/
├── content/
│   ├── site.json            # name, bio, email, LinkedIn, featured projects, resume
│   └── projects/<slug>.json # one file per project: copy, media blocks, cover
├── static/                  # stylesheet, lightbox JS, favicon
├── process_media.py         # source photos/videos -> optimized docs/assets/
├── build.py                 # content JSON -> HTML pages in docs/
└── docs/                    # the finished site (upload anywhere)
```

## Editing

- **Change a cover photo**: edit the `"cover"` path in that project's JSON.
- **Add an image/video to a project**: drop the file in the project's folder in
  `Portfolio Files/`, add an `{"type": "image"|"video", "source": "../<folder>/<file>", "caption": "..."}`
  block to the project JSON (any position — media and text interleave freely).
- **Add a project**: create a new `content/projects/<slug>.json` (copy an
  existing one) and set its `"order"`.
- **Swap in the real resume PDF**: put the PDF anywhere in `Portfolio Files/`,
  set `"resume_pdf"` in `site.json` to its relative path (e.g. `"../resume.pdf"`).

Media paths in `"source"`/`"cover"` are relative to `portfolio-site/`, so
`../EMG Claw Project/photo.png` points at the original asset library.

## Building

```sh
python3 process_media.py   # only needed when source media changed
python3 build.py           # regenerates all HTML (fast)
```

Preview locally: `python3 -m http.server 4173 --directory docs` then open
http://localhost:4173.

## Deploying

`docs/` is plain HTML/CSS/JS — host it on GitHub Pages, Netlify, Cloudflare
Pages, or any static host. No build step is required on the server.
