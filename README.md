# ReactOS Internals

A guided, annotated tour of the [ReactOS](https://github.com/reactos/reactos) source for people who want to contribute.

- **The tour:** real ReactOS source files with inline annotations, following one `CreateFileW` call from kernel32 down to the file system driver, plus architecture diagrams.
- **Contributor's guide:** the clean-room rule, building, finding a first task, tests, code style and the pull request workflow, summarized from the project's own documents.

The site is built on the [Code Museum](https://github.com/PatAltimore/code-museum) reader, specialised to a single program. Pages are published from `public/` by `.github/workflows/pages.yml` (Settings, Pages, Source: GitHub Actions).

## Layout

```
public/
├── index.html, css/, js/app.js   # the reader (hash-routed single page app)
├── catalog.json                  # program, files, highlights, diagrams, guide list
├── programs/reactos/*.md         # annotated source: YAML frontmatter + the code
└── guide/*.md                    # contributor guide pages (Markdown)
```

Each annotated file is a Markdown file whose frontmatter lists `enhancements` anchored to line ranges of the code below it. Code links and line numbers refer to the fork snapshot `PatAltimore/reactos` @ `e46f4bb1`. A local clone for reading the source goes in `reactos/` (git-ignored):

```bash
git clone --depth 1 https://github.com/PatAltimore/reactos.git reactos
```

## Running locally

```bash
npx serve public
```

Diagrams are [Mermaid](https://mermaid.js.org) and the guide uses [marked](https://marked.js.org); both load from the CDN, pinned with integrity hashes, only on pages that need them.

## Contributing to this site

Annotations are hand-written, so please verify line numbers against the pinned commit. ReactOS is clean-room: never base annotations on Microsoft Windows source code.
