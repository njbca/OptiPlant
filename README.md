# OptiPlant

OptiPlant is a tool that enables the user 
to model Power-to-X fuel production systems with a high variety of customizable input parameters and to optimize them according to different criteria. 
The model works under the ‘dynamic power supply and system optimization’ approach (DPS-Syst-Opt).

The current model optimize the operation and investment of an e-ammonia or e-methanol plant.
The plant can be powered by solar, wind or the grid. All the data in the files "Bornholm_2030_large_scale_scenario_data" or "Bornholm_2030_small_scale_scenario_data" are valid for near future (2030). 

The article that uses and describes the model, the input data, and the underlying assumptions is: 

Antoine Letoffet, Nicolas Campion, Moritz Böhme, Claus Dalsgaard Jensen, Jesper Ahrenfeldt, Lasse Røngaard Clausen (2024).
Techno-economic assessment of upgraded pyrolysis bio-oils for future marine fuels,
Energy Conversion and Management, Volume 306, 118225.
ISSN 0196-8904.
https://doi.org/10.1016/j.enconman.2024.118225.
(https://www.sciencedirect.com/science/article/pii/S0196890424001663)

## Software Installation

A detailed installation guide for the software needed to run OptiPlant is included within the document **OPTIPLANT tool. User guide** found in this page.

Download the user guide and follow the steps to install all the necessary software.

The detailed step-by-step instructions described in the user guide can be simplified as follows:

1- Download and install [Julia](https://julialang.org/downloads/)

2- Download and install a code editor like [VSCode](https://code.visualstudio.com/). Add the *Julia* extension in the code editor.

3- Add and install the necessary packages to your VSCode environment such as: JuMP, HiGHS, XLSX, DataFrames and CSV

4- (optional)- Get a license and install the [Gurobi](https://www.gurobi.com/downloads/) package. You need to activate it using the grbgetkey.


## Running the OptiPlant tool model

A detailed walk-through on how to use OptiPlant is also included within the document **OPTIPLANT tool. User guide** found in this page.

The detailed step-by-step instructions described in the user guide can be simplified as:

1- Download all the OptiPlant ZIP folder from https://github.com/njbca/OptiPlant/tree/OptiPlant-upgraded-bio-oils (Go to the green 'Code' button on this page, and click on 'Download ZIP').

2- Modify/tune the parameters found in the Base > Data folder: Techno-economical data ('Inputs') and/or wind and solar profiles, and electricity prices ('Profiles')  

3- Install the necessary software: Julia, VSCode and add the necessary packages (JuMP, HiGHS, XLSX, DataFrames and CSV). Open the Main.jl Julia file found in the Run Code folder.	 Edit the code if necessary. Run the code file

4- Check the obtained outcomes (CSV) in the defined drectory inside the Base > Results folder. Import the CSV data to the ‘Results’ excel file found in the same folder to process and visualize the model outcomes

  


### *Description of the folder structure:*

``"BASE"`` is the main "project" folder. If you want to create another project, copy this folder and rename it to your preference. 
It includes the subfolders ``"Data"`` and ``"Results"``.

``"Data"`` folder contains all the necessary data to run the model. In the subfolder ``"Profiles"``, one can check and modify the wind/solar profiles 
and the electricity prices of different locations during different years. In the subfolder ``"Inputs"``there are excel 
different excel sheets where one can check and modify the input data for different study-case scenarios such as: units conforming for the PtX plant, 
their techno-economic information, the operation strategy of the plant,etc.

``"Results"`` folder has the results/outputs of the simulation. A new folder will be created any time a simulation is run, and
its name would correspond to the one written in the ‘Inputs excel sheet’. Includes different subfolders: Data used,
Hourly results and Main results.


``"CODE"`` includes four Julia scripts named ImportData.jl, ImportScenarios.jl, and Main.jl.


A more detailed description of each folder and their files can (again) be found in the **OPTIPLANT tool. User guide**


### *Filling the 'Inputs' data file:* 

Go to the ``"Inputs"``subfolder and open or create a copy of any of the template files found there. Next, do the following:

a) Fill the ``"Data_base_case"`` sheet with your own techno-economic data (if you changes names in red, it is also necessary to change the 
*Import_data* or *Import_scenarios* julia code files). 

b) In the ``"Selected_units"`` data sheets you can decide to exclude some units from the optimization run (make sure to avoid solving infeasibility by doing so).

c) In the ``"Scenarios_definition"`` sheet, define your scenario(s) name(s) and which data are changed in this scenario compared to the values indicated in the "Data_base_case" sheet.

d) In the ``"ScenariosToRun"`` sheet -create one if needed-, define which scenarios you want to run and the assumptions 
(update the name of this excel sheet on the *Main* julia code files if you change its name). 

e) Save all the files you changed.

Additional information on how the input data files work is included in the **2) OptiPlant tool: User guide**


### *Run the model and get the results:* 

Go to the ``"Run Code"`` folder and open the ``"Main.jl"``,  ``"ImportData.jl"``, and ``"ImportScenarios.jl"`` files. Do the following checks/changes on the ``"Main.jl"`` file:

a) Change the "Main folder" to the correct directory path of your Optiplant folder (make sure the path directories for the other two code files are also correctly written).

b) Define/rewrite the name of which scenarios from the "ScenariosToRun" excel sheet (input data) you want to run.

c) Modify the maintenance hours of the plant and the number of working hours for the simulation (max 8760), the currency change, etc. if needed (all input data are currently in €2019).

e) Run the code.


Results appears as CSVs in a result folder previously specified in the ``"Scenarios"`` excel sheet (input data). Running again without changing the destination folder will overwrite the previous results. 
Import the CSV data to the ‘Results’ excel file found in the same folder to process and visualize the model outcomes
