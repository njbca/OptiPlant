# OptiPlantPtX

**GitHub Repository:** [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)

[![Build Status](https://github.com/njbca/OptiPlant/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/njbca/OptiPlant/actions/workflows/CI.yml?query=branch%3Amain)
[![Julia Version](https://img.shields.io/badge/julia-1.11+-blue.svg)](https://julialang.org)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://njbca.github.io/OptiPlant/)
[![License](https://img.shields.io/github/license/njbca/OptiPlant)](https://github.com/njbca/OptiPlant/blob/main/LICENSE)

OptiPlant can be used to model and optimize Power-to-X fuel production systems with a high variety of customizable input parameters. The tool is adapted to investigate a large number of scenarios and system configurations in a single run. Please cite https://doi.org/10.1016/j.rser.2022.113057 when using the model.

## Documentation

- **[� DOCUMENTATION](https://njbca.github.io/OptiPlant/)** — Complete documentation with installation guide, usage examples, and API reference.

## Guide for software installation and test run
This guide will walk you through setting up the repository locally, configuring your environment, and running the model.

## Clone the Repository

Set up a [GitHub account](https://github.com/signup), sign-in and install a Git client (choose one you’re comfortable with):  
- [GitHub Desktop](https://desktop.github.com/) (recommended for beginners)  
- [Git](https://git-scm.com/downloads)  

### Steps (with GitHub Desktop):
1. On the (current) OptiPlantPtX.jl page, click on the green "<> Code" button, go to HTTPS and copy the URL
2. In GitHub desktop, go to `File > Clone repository` 
3. Go in the URL tab and paste the OptiPlant.jl repository URL
4. Choose the path to clone the repository locally: **installing on Drive may cause problems!**  

## Open in VS Code

Download and install [Visual Studio Code](https://code.visualstudio.com/). 
Make sure to select the "Add to PATH" option when installing. 

1. Open VS Code  
2. Go to `File > Open Folder` → select your `OptiPlantPtX.jl` folder  

## Setup Julia Environment

Make sure you have the **latest Julia version** installed: [Install Julia](https://julialang.org/install/).

1. Add the *Julia* extension in VS Code using the "Extensions: Marketplace" (access on the square icon on left sidebar of VS Code)

2. Open the Julia REPL inside VS Code (the first time opening can take a bit of time):  
   - Press `Alt + J` then `Alt + O`  

3. Move one directory up:  
   ```julia
   cd("..")
   ```
4. Press `]` to enter the package manager

5. To set up the environment write
    ```julia
    activate OptiPlantPtX.jl
    ```
    followed by
    ```julia
    instantiate
    ```
    For more detailed explanations, refer to the Julia documentation: [Using someone else's project](https://pkgdocs.julialang.org/v1/environments/).

6. To use Gurobi as a solver, you need to [install the software](https://www.gurobi.com/downloads/) and activate your license using the grbgetkey. Overtime, you may need to update Gurobi to the latest version and re-generate your license to avoid license compatibility issues.

7. Done! You can exit the package manager pressing the `Backspace key`


## Running the Project

1. In VSCode, open the `Run.jl` file.
2. If Gurobi is not installed, make sure that the selected solver is `"HiGHS"`
2. Click the little arrow on top of VS Code to execute it.

No errors? Great! You can now start using the tool.

## Documentation (building locally)

This repository uses Documenter.jl to build the docs in `docs/`.

From the repository root (PowerShell):

```powershell
# Build the documentation locally
julia --project=docs -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
julia --project=docs docs/make.jl
```

If you want to build the dashboards locally, see `docs/src/Examples.md` for a
quick example of running the Streamlit dashboards.

## Making Modifications (Mandatory!)

1. On the online repository, click on **Fork >  Create a new fork**.
2. Always make sure that you are working on your fork when making modifications (not on the main branch).
3. Contact me before contributing to the main branch.
4. For adding new data: copy one of the existing data folder, rename it, and then change the excel files to your convenience (do not change any of the existing excel files)

## Documentation and Resources

- **📖 [Complete Documentation](docs/build/index.html)** - Comprehensive guides and API reference
- **🚀 [Quick Start Guide](docs/src/installation.md)** - Get up and running quickly
- **💡 [Usage Examples](docs/src/Examples.md)** - Practical examples and use cases
- **🔧 [API Reference](docs/src/api.md)** - Detailed function documentation
- **📊 [Interactive Dashboards](src/PlotGraphs/)** - Streamlit visualization tools
- **🐛 [Issues & Bug Reports](https://github.com/njbca/OptiPlant/issues)** - Report problems or request features
- **💬 [Discussions](https://github.com/njbca/OptiPlant/discussions)** - Community support and questions

## Citation

When using OptiPlant in your research, please cite:

```bibtex
@article{campion2023optimization,
  title={Optimization and analysis of large-scale renewable fuel production systems},
  author={Campion, Nicolas and Barbosa, J and Mohammadi, A and Lund, H},
  journal={Renewable and Sustainable Energy Reviews},
  volume={171},
  pages={113057},
  year={2023},
  doi={10.1016/j.rser.2022.113057}
}
```


