# Contributing to OptiPlant.jl

Thank you for contributing! This file contains a minimal checklist and steps to
prepare a branch and pull request that will pass Continuous Integration (CI).

Checklist before opening a PR

- [ ] Pull the latest `main` into your feature branch and resolve conflicts locally.
- [ ] Run the unit tests (if any) and ensure they pass.
- [ ] Build the documentation locally (see below) and ensure `docs/make.jl` runs.
- [ ] Add or update documentation for any user-facing changes.
- [ ] Update `README.md` or `docs/src` as appropriate.

How to run checks locally (Windows PowerShell)

1. Activate the Julia project and install dependencies:

```powershell
julia --project -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
```

2. Build the documentation (this uses the `docs/` Project.toml):

```powershell
julia --project=docs -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
julia --project=docs docs/make.jl
```

3. Install Python dependencies for dashboards and run Streamlit if needed:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
streamlit run src/PlotGraphs/Dashboard_CO2.py
```

PR acceptance notes for maintainers

- Check CI logs for the `Documentation` job (build-docs). If it fails with a
  missing `docs/make.jl`, ensure the PR branch contains the `docs/` folder and
  the workflow checkout path is correct.
- If Documenter fails to `using OptiPlantPtX`, check that `src/` contains
  `OptiPlantPtX.jl` and that `docs/make.jl` adds `src` to `LOAD_PATH`.
