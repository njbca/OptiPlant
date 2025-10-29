# OptiPlant.jl — Introduction

Welcome to the OptiPlant.jl documentation. This is a minimal documentation site to
get started. It follows the structure used by other Julia packages (e.g. CSV.jl)
so the repository contains a `docs/` folder with a `make.jl` script and a
`docs/src` folder with Markdown pages.

What you'll find here soon:

- Overview of the model and goals
- Quick start: how to run the Julia runner and the Streamlit dashboards
- Examples showing how to set up and run scenarios

This page is intentionally short for now — expand it with usage examples and
API references as the project stabilizes.

---

## Quick local check

From the repository root (PowerShell):

```powershell
# Activate the docs environment and build the docs locally
julia --project=docs -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
julia --project=docs docs/make.jl
```

If Documenter cannot `using OptiPlantPtX`, make sure the package `src` directory
is present and that `Project.toml` in the repository root matches the package
name/uuid.
<!--
Intro.md
Purpose: project overview and installation instructions.
What to fill: replace placeholders below with concrete installation steps,
description of the project, and a minimal quick-start example.
-->

# OptiPlantPtX

OptiPlantPtX is a Julia package for optimizing and analyzing energy plant configurations. This documentation contains an introduction, examples, and API references. Fill in the sections below with project-specific details.

## Project metadata

- Package name: `OptiPlantPtX`
- UUID: `036e4454-802e-43b1-820d-78f38b913b71`
- Authors: Nicolas Campion
- Julia compatibility: 1.11

## Installation

To install the package (once registered or if available locally):

```julia
using Pkg
Pkg.add(path="/path/to/OptiPlant.jl") # or Pkg.add("OptiPlantPtX") if registered
```

To build documentation locally (recommended inside a Julia REPL):

```julia
using Pkg
Pkg.activate("docs")
Pkg.instantiate()
include("docs/make.jl")
```

## Quick start

Below is a minimal usage example — replace with real code for your project:

```julia
using OptiPlantPtX

# create a simple model or load an example input
# result = OptiPlantPtX.run_example()
```

## Where to edit

- `docs/src/Intro.md` — this file (project overview and installation)
- `docs/src/Examples.md` — longer examples and tutorials
- `docs/make.jl` — Documenter build configuration
