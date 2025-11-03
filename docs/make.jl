"""
Minimal Documenter build script for OptiPlant.jl.

This script is intentionally defensive:
- it ensures the package `src` directory is on LOAD_PATH so `using OptiPlantPtX`
  works regardless of the working directory layout on CI (avoids missing-file
  errors when the repo is checked out under a different folder name).
- it provides a minimal set of pages under `docs/src` so the docs job can run.

Adjust `modules`, `pages`, and `repo` below as the documentation grows.
"""

import Pkg

# Ensure the docs project is activated and dependencies are available.
# This makes it easier to run `docs/make.jl` directly (it will try to
# instantiate the `docs/` environment if needed). If you prefer to run
# manually, use: julia --project=docs -e "using Pkg; Pkg.instantiate()"
try
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
catch err
    @warn "Could not activate/instantiate docs environment; you may need to run 'julia --project=docs -e \"using Pkg; Pkg.instantiate()\"' manually" error=err
end

using Documenter

# Make sure the package `src` directory is on LOAD_PATH so `using OptiPlantPtX`
# works even if CI checks out the repository under a different parent folder
# (this avoids include/Path errors when Documenter runs on GitHub Actions).
push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..", "src")))

success_using = false
try
    using OptiPlantPtX
    success_using = true
catch err
    @warn "Could not `using OptiPlantPtX` from docs; building docs without the package module" error=err
end

# make sure `modules` is either a Vector{Module} or an empty Module vector
modules_list = success_using ? [OptiPlantPtX] : Module[]

makedocs(
    modules = modules_list,
    sitename = "OptiPlant.jl",
    authors = "Nicolas Campion, Sebastian Banda",
    repo = "https://github.com/njbca/OptiPlant",
    pages = [
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Usage" => "usage.md", 
        "Examples" => "Examples.md",
        "API Reference" => "api.md",
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://njbca.github.io/OptiPlant/",
        edit_link = "Development",
        assets = String[],
        repolink = "https://github.com/njbca/OptiPlant",
    )
)

# Deploy documentation to GitHub Pages
if get(ENV, "CI", nothing) == "true"
    deploydocs(
        repo = "github.com/njbca/OptiPlant",
        devbranch = "Development",
        push_preview = true
    )
end