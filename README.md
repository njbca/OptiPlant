# OptiPlantPtX

[![Build Status](https://github.com/njbca/OptiPlant.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/njbca/OptiPlant.jl/actions/workflows/CI.yml?query=branch%3Amain)

OptiPlant can be used to model and optimize Power-to-X fuel production systems with a high variety of customizable input parameters. The tool is adapted to investigate a large number of scenarios and system configurations in a single run. Please cite https://doi.org/10.1016/j.rser.2022.113057 when using the model.

## Installation in short

If you are already familiar with GitHub, environments, etc... you can basically follow these steps:
   1. Fork the repository (including this branch)
   2. Clone the repository to your local machine
   3. Open in VS Code
   4. [Setup Julia Environment](https://pkgdocs.julialang.org/v1/environments/)

Though, for more detailed instructions and avoid failed installations, it is recommended to read the documentation: https://njbca.github.io/OptiPlant/dev/installation/

## Running one of the examples

1. In VSCode, in the open the `Run.jl` file from the `examples` folder.
2. If Gurobi is not installed, make sure that the selected solver is `"HiGHS"`
3. Execute the code (little arrow top left).

No errors? Great! A result folder full of interesting csv files should have appeared.
You can now start using the tool for more useful stuff.

## How to use the tool

Most of the tool parameter setting, scenario selection, etc... happens in the excel files in the `data` folder.

To start your own project, copy one of the existing data folder (the `example` one typically), rename it, and then change the excel files to your convenience.

In the `Run.jl`file change the `datafoldername` and `techno_eco_filename` to yours.

Run and check your results in the results folder. 

More detailed explanations are given in the documentation: https://njbca.github.io/OptiPlant/dev/usage/ 

## Use the data analysis dashboards

To use the data analysis dashboards and analyze the results write in the powershell terminal:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
streamlit run src/PlotGraphs/Dashboard_Scenarios.py
```

Otherwise you can also use the result excel file coming with the package (`Results_general.xlsm`) or use your own analysis method.


#Test lines
using Pkg
Pkg.add("OptiPlantPtX")
julia --project=. setup_python.jl  # install Python packages
using OptiPlantPtX
