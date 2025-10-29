# Explanation of added files (short)

This repository previously had no `docs/` site. The following minimal files
were added so the documentation job on GitHub Actions can run and so the
`docs/` folder is visible in the `main` branch of the repository.

Files added and purpose:

- `docs/make.jl` — Documenter build script. It now contains safety logic to
  activate the docs project and to avoid failing if the package cannot be
  imported on CI. You can run it directly: `julia docs/make.jl`.
- `docs/Project.toml` and `docs/Manifest.toml` — the docs project environment
  (Documenter listed as a dependency). These let CI `Pkg.instantiate()`.
- `docs/src/index.md`, `docs/src/Intro.md`, `docs/src/Examples.md` — minimal
  markdown pages so Documenter has content to render.
- `docs/DASHBOARDS.md` — instructions for running the Streamlit dashboards.
- `CONTRIBUTING.md` — minimal contributing guidance and checks for opening PRs.
- `requirements.txt` — Python dependencies required to run the dashboards.

Notes and how to update:
- If you later add API docs that `using` the package requires, it's fine; the
  `docs/make.jl` script will try to `using OptiPlantPtX` but will continue if
  it cannot. For full API docs, install package dependencies or add them to
  `docs/Project.toml`.
- To preview changes locally, run the `julia --project=docs docs/make.jl`
  command and open `docs/build/Intro/index.html` in your browser.
