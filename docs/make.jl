import Pkg

# Ensure the docs project is activated and dependencies are available.
# This makes it easier to run `docs/make.jl` directly (it will try to
# instantiate the `docs/` environment if needed). If you prefer to run
# manually, use: julia --project=docs -e "using Pkg; Pkg.instantiate()"

try
    Pkg.activate(@__DIR__)
    #Pkg.develop(path = joinpath(@__DIR__, ".."))
    Pkg.instantiate()
catch err
    @warn "Could not activate/instantiate docs environment; you may need to run 'julia --project=docs -e \"using Pkg; Pkg.instantiate()\"' manually" error=err
end

using Documenter

# Build documentation without loading the full module to avoid dependency issues
modules_list = Module[]

makedocs(
    sitename = "OptiPlantPtX.jl",    
    modules = modules_list,
    authors = "Nicolas Campion, Sebastian Banda",
    repo = "https://github.com/njbca/OptiPlant",
    pages = [
        "Home" => "index.md",
        "Introduction" => "introduction.md",
        "Installation" => "installation.md",
        "User-guide" => "usage.md", 
        "Data dashboard" => "dashboards.md"
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

deploydocs(
    repo = "github.com/njbca/OptiPlant",
    devbranch = "Development",
    push_preview = true
)
