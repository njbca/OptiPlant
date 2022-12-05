# OptiPlant

The current model optimize the operation and investment of an e-ammonia plant.
The plant can be powered by solar, wind or the grid. All the data in the files are valid for near future (2020-2025) and large scale plant. 

The article describing the model, data and underlying assumptions can be found here : https://doi.org/10.1016/j.rser.2022.113057

## Installation

1- Install a code editor like [VSCode](https://code.visualstudio.com/). Atom may also work. 

2- Install [Julia](https://julialang.org/downloads/) and add it in VSCode. 

3- Download all the Optiplant github folder and unzip. 

4- Install all the necessary Julia packages: ExcelReaders, JuMP, CSV, DataFrames, Gurobi. Other solvers may be used but solving time may be higher and the user may need to run the model with representative days or weeks instead of a full year. Use ``Pkg.add("PackageName")``  in Julia to install the different packages and their dependencies.

5- To use the environment provided, uncomment the line ``cd(joinpath(Main_folder,"envgit")) ; Pkg.activate(pwd())`` in the ``Main.jl`` file (Code folder)

## Using the model

### Description of the folder structure

``"Base"`` is the main "project" folder. If you want to create another project, copy the ``"Base"`` folder and rename it to your preference. 

``"Data"`` folder contains all the necessary data to run the model. In ``"Profiles"``, you can define the normalized hourly power profiles (between 0 and 1) for a specific location and the hourly grid electricity prices (the excel file and the folder should have the same name). The type of file used should be ``.xls``.

In ``"Inputs"``there is a file called like "project folder"_"file name.xls". This one containts all the techno-economic assumptions and scenarios definitions.

### Filling the inputs data file

1- Fill the ``"Data_base_case"`` sheet with your own techno-economic data (if you changes names in red, it is also necessary to change the Import_data or Import_scenarios julia code).

2- In the ``"Selected_units"`` data sheets you can decide to exclude some units from the optimization run (make sure to avoid solving infeasibility by doing so).

3- In the ``"Scenarios_definition"`` sheet, define your scenario name and which data are changed in this scenario compared to the values indicated in the "Data_base_case" sheet.

4- In the ``"Scenarios"`` sheet, define which scenarios you want to run and the assumptions.

5- Save all the files you changed..

### Run the model

1- Go to the code folder and open the ``"Main"`` julia file.

2- In the problem set up section change the "Main folder" to the path of your Optiplant folder.

3- Define which scenarios from the "Scenarios" sheet you want to run.

4- Set the maintenance hours of the plant and the number of hours for the simulation (max 8760). The starting time (Tbegin) is the time from which all units must operates above their minimal loads. 

5- Choose the currency change if needed (all input data are currently in €2019).

6-Run.

7-Results appears as CSVs in a result folder previously specified in the ``"Scenarios"`` sheet. Running again without changing the destination folder will overwrite the previous results. 

