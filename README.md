# OptiPlantPtX

[![Build Status](https://github.com/njbca/OptiPlant.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/njbca/OptiPlant.jl/actions/workflows/CI.yml?query=branch%3Amain)

OptiPlant can be used to model and optimize Power-to-X fuel production systems with a high variety of customizable input parameters. The tool is adapted to investigate a large number of scenarios and system configurations in a single run. Please cite https://doi.org/10.1016/j.rser.2022.113057 when using the model.

The full documentation is available here: https://njbca.github.io/OptiPlant/index.html 

## Guide for software installation and test run
This guide will walk you through setting up the repository locally, configuring your environment, and running the model.

## Fork the repository

Set up a [GitHub account](https://github.com/signup) and sign-in.
On the online repository, click on **Fork >  Create a new fork** and name it as you wish i.e. `OptiPlant`.

## Clone the repository to your local machine

Install a Git client (choose one you’re comfortable with):  
- [GitHub Desktop](https://desktop.github.com/) (recommended for beginners)  
- [Git](https://git-scm.com/downloads)  

### Steps (with GitHub Desktop):
1. On the OptiPlant repository that you forked, click on the green "<> Code" button, go to HTTPS and copy the URL
2. In GitHub desktop, go to `File > Clone repository` 
3. Go in the URL tab and paste the OptiPlant repository URL
4. Choose the path to clone the repository locally: **installing on a Drive may cause problems!**  

## Open in VS Code

Download and install [Visual Studio Code](https://code.visualstudio.com/). 
Make sure to select the "Add to PATH" option when installing. 

1. Open VS Code  
2. Go to `File > Open Folder` → select your `OptiPlant` folder  

## Setup Julia Environment

Make sure you have the **latest Julia version** installed: [Install Julia](https://julialang.org/install/).

1. Add the *Julia* extension in VS Code using the "Extensions: Marketplace" (access on the square icon on left sidebar of VS Code)

2. Open the Julia REPL inside VS Code (the first time opening can take a bit of time):  
   - Option 1, keyboard shortcut: Press `Alt + J` then `Alt + O` 
   - Option 2, open the command palette (`Ctrl+Shift+P`) and run: `Julia: Start REPL`

This is now a condensed version of the [Julia documentation](https://pkgdocs.julialang.org/v1/environments/) to use someone else's project.

3. In the REPL, run this comand to move one directory up (where the folder where `OptiPlant` is located):  
   ```julia
   cd("..")
   ```
4. Press `]` to enter the package manager

5. To set up the environment write
    ```julia
    activate OptiPlantPtX
    ```
    followed by
    ```julia
    instantiate
    ```

6. To use Gurobi as a solver, you need to [install the software](https://www.gurobi.com/downloads/) and activate your license using the grbgetkey. Overtime, you may need to update Gurobi to the latest version and re-generate your license to avoid license compatibility issues.

7. Done! You can exit the package manager pressing the `Backspace key`


## Running one of the examples

1. In VSCode, in the open the `Run.jl` file from the `examples` folder.
2. If Gurobi is not installed, make sure that the selected solver is `"HiGHS"`
2. Click the little arrow on top of VS Code to execute it.

No errors? Great! A result folder should have appeared.
You can now start using the tool for more interesting stuff.

## How to use the tool

Most of the tool parameter setting, scenario selection, etc... happens in the excel files in the `data` folder.

To start your own project copy one of the existing data folder, rename it, and then change the excel files to your convenience (avoid changing the existing excel files).

In the `Run.jl`file change the `datafoldername` and `techno_eco_filename` to yours.

More detailed explanations are given in the documentation: https://njbca.github.io/OptiPlant/index.html 

## Use the data analysis dashboards

To use the data analysis dashboards and  analyze the results write in the powershell terminal:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
streamlit run src/PlotGraphs/Dashboard_Scenarios.py
```
