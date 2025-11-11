# Contributing to OptiPlantPtX.jl

Thanks for contributing!

When doing modifications, always make sure that you are working on your fork.
For more advanced collaborations, tool usage or specific inquiries please contact [njbca@dtu.dk](mailto:njbca@dtu.dk) 

## Build the documentation locally

This repository uses Documenter.jl to build the docs in `docs/`.

From the repository root (PowerShell):

```powershell
# Build the documentation locally
julia --project=docs -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
julia --project=docs docs/make.jl
```