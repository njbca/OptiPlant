# OptiPlant

OptiPlant is a tool that enables the user 
to model Power-to-X fuel production systems with a high variety of customizable input parameters and to optimize them according to different criteria. 
The model works under the ‘dynamic power supply and system optimization’ approach (DPS-Syst-Opt).

The current model optimize the operation and investment of an e-ammonia plant.
The plant can be powered by solar, wind or the grid. All the data in the files are valid for near future (2020-2025) and large scale plant. 

An article that describes the model, the input data, and the underlying assumptions is: 

Campion, N., Nami, H., Swisher, P. R., Vang Hendriksen, P., & Münster, M. (2023). 
Techno-economic assessment of green ammonia production with different wind and solar potentials. 
Renewable and Sustainable Energy Reviews, 173, 113057. 
https://doi.org/10.1016/j.rser.2022.113057

## Software Installation

A detailed installation guide for the software needed to run OptiPlant is included in this page under the name: 
**1) Installation guide: software needed to run OptiPlant tool**.

Download the document and follow the steps to install all the necessary software.

The detailed step-by-step instructions described in the installation guide can be simplified as:

1- Download and install [Julia](https://julialang.org/downloads/)

2- Download and install a code editor like [VSCode](https://code.visualstudio.com/). Add the *Julia* extension in the code editor.

3- Get a license and install the [Gurobi](https://www.gurobi.com/downloads/) package. You need to activate it using the grbgetkey.

4- Add and install other packages to your VSCode environment such as: JuMP, CSV, ExcelReaders, Plots,...


## Running the OptiPlant tool model

A detailed OptiPlant user guide is included in this page under the name: 
**2) OptiPlant tool: User guide**.

The detailed step-by-step instructions described in the user guide can be simplified as:

1- Download all the Optiplant Github folder (Go to the green 'Code' button on this page, and click on 'Download ZIP').

2- Insert/change the desired input parameters (files inside ``"Data"`` folder) and run the *Julia* code files to get the results/outcomes 
-see sections below-. 


### *Description of the folder structure:*

``"BASE"`` is the main "project" folder. If you want to create another project, copy this folder and rename it to your preference. 
It includes the subfolders ``"Data"`` and ``"Results"``.

``"Data"`` folder contains all the necessary data to run the model. In the subfolder ``"Profiles"``, one can check and modify the wind/solar profiles 
and the electricity prices of different locations during different years The type of files used should be ``.xls``. In the subfolder ``"Inputs"``there are excel 
different excel sheets where one can check and modify the input data for different study-case scenarios such as: units conforming for the PtX plant, 
their techno-economic information, the operation strategy of the plant,etc.

``"RESULTS"`` folder has the results/outputs of the simulation. A new folder will be created any time a simulation is run, and
its name would correspond to the one written in the ‘Inputs excel sheet’. Includes different subfolders: Data used,
Hourly results and Main results.


``"CODE"`` includes four Julia scripts named ImportData.jl, ImportScenarios.jl, Main.jl, and Main stochastic.jl


A more detailed description of each folder and their files can be found in the **2) OptiPlant tool: User guide**


### *Filling the inputs data file:* 

Go to the ``"Inputs"``subfolder and open or create a copy of any of the template files found there. Next, do the following:

a) Fill the ``"Data_base_case"`` sheet with your own techno-economic data (if you changes names in red, it is also necessary to change the 
*Import_data* or *Import_scenarios* julia code files). 

b) In the ``"Selected_units"`` data sheets you can decide to exclude some units from the optimization run (make sure to avoid solving infeasibility by doing so).

c) In the ``"Scenarios_definition"`` sheet, define your scenario(s) name(s) and which data are changed in this scenario compared to the values indicated in the "Data_base_case" sheet.

d) In the ``"Scenarios ***"`` sheet -create one if needed-, define which scenarios you want to run and the assumptions 
(update the name of this excel sheet on the *Main* julia code files).. 

e) Save all the files you changed.

Additional information on how the input data files work is included in the **2) OptiPlant tool: User guide**


### *Run the model:* 

Go to the ``"CODE"`` folder and open the ``"Main.jl"``,  ``"ImportData.jl"``, and ``"ImportScenarios.jl"`` files. Do the following changes on the ``"Main.jl"`` file:

a) Change the "Main folder" to the correct directory path of your Optiplant folder (make sure the path directories for the other two code files are also correctly written).

b) Define/rewrite the name of which scenarios from the "Scenarios" excel sheet (input data) you want to run.

c) Modify the maintenance hours of the plant and the number of working hours for the simulation (max 8760) and/or the currency change, if needed (all input data are currently in €2019).

e) Run the code.


Results appears as CSVs in a result folder previously specified in the ``"Scenarios"`` excel sheet (input adta). Running again without changing the destination folder will overwrite the previous results. 

