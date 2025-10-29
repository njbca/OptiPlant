# Documentation (template)

This repository contains a `docs/` folder configured to build documentation using Documenter.jl.

Local build instructions:

1. Install Julia (1.11 recommended).
2. Activate the docs project and install dependencies:

```powershell
julia -e "using Pkg; Pkg.activate(\"docs\"); Pkg.instantiate()"
```

3. Build the documentation locally:

```powershell
julia --project=docs docs/make.jl
```

Edit the documentation content in `docs/src/` (for example `Intro.md` and `Examples.md`). If your package module is named differently than `OptiPlantPtX`, update `docs/make.jl` accordingly.
