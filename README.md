# OptiPlant

OptiPlant is a tool that enables the user 
to model Power-to-X fuel production systems with a high variety of customizable input parameters and to optimize them according to different criteria. 
The tool is adapted to investigate a large number of scenarios and system configurations in a single run. 

The current model optimize the operation and investment of an e-ammonia, e-methanol or upgraded pyrolysis oil plant.
The plant can be powered by solar, wind and/or the grid.  

The article that describes the model, the input data (in "Data_ammonia_paper"), and the underlying assumptions for ammonia production is: 

Campion, N., Nami, H., Swisher, P. R., Vang Hendriksen, P., & Münster, M. (2023). 
Techno-economic assessment of green ammonia production with different wind and solar potentials. 
Renewable and Sustainable Energy Reviews, 173, 113057. 
https://doi.org/10.1016/j.rser.2022.113057

The tool now includes concentrated solar power (CSP) technologies and thermal energy storage (TES). Methods, input data (in "Data_CSP_paper") and assumptions are explained in: https://doi.org/10.1016/j.renene.2024.121410

The tool have also been used to lead techno-economic assessments of [upgraded pyrolysis bio-oils](https://doi.org/10.1016/j.enconman.2024.118225) (see the specific branch) and [DME](https://doi.org/10.1021/acs.energyfuels.4c00311). 
The tool has been used [here](https://doi.org/10.1016/j.rser.2024.115044) and a more [specialized version](https://github.com/giumonros/Measured-vs-simulated-PV/tree/main) have been developped to study the influence of using measured or simulated solar PV data on hydrogen techno-economic assessments (input file "Meas_vs_sim_data").
Other related works are also available [here](https://orbit.dtu.dk/en/persons/nicolas-jean-bernard-campion/publications/)

## Quick guide for software installation and model test run

A detailed installation guide for the software needed to run OptiPlant is included within the document **OPTIPLANT tool-User guide** that can be found inside
the folder ``"User-guide"`` on this page.

Download the user guide and follow the steps to install all the necessary software and run the model.

The detailed step-by-step instructions described in the user guide can be simplified as follows:

1- Download all the OptiPlant ZIP folder from https://github.com/njbca/OptiPlant (Go to the green 'Code' button on this page, and click on 'Download ZIP'). Unzip the folder. If you are using GitHub you can also Fork and Clone the repository.

2- Download and install [Julia](https://julialang.org/downloads/). Add Julia to PATH **ONLY if** you had VS Code already installed.

3- Download and install a code editor like [VSCode](https://code.visualstudio.com/). Make sure to select the "Add to PATH" option when installing. 

4- Add the *Julia* extension in the code editor (Extensions marketplace on the left sidebar).

5- Add and install the necessary packages to your VSCode environment such as: JuMP, HiGHS, XLSX, DataFrames and CSV. To do so write `]` in the Julia/REPL prompt to open the package manager. Then write `add *Package name*`.

6- (optional)- Get a license and install the [Gurobi](https://www.gurobi.com/downloads/) package. You need to activate it using the grbgetkey.

7- Know you can (finally!) test run the model: open the Main.jl Julia file found in the Run Code folder. Edit the code changing the folder directory (depending on the place where you stored the unzipped file on your PC). Run the code file.

8- Check the obtained outcomes (CSV) in the defined directory inside the Base > Results folder. Import the CSV data to the ``"Results_general.xlsm"`` excel file found in the same folder to process and visualize the model outcomes. 
The files ``"Results_mvssim.xlsm"`` and ``"R_mvssim_sensitities.xlsm"`` are for extracting the results specific to the input data file "Meas_vs_sim_data" and [this study](https://doi.org/10.1016/j.rser.2024.115044).

## Using the OptiPlant tool

The user-guide **OPTIPLANT tool-User guide** provides all the details about the use of the OptiPlant tool.
This section summarizes briefly the main features of the tool and the basics to use it.
The tool itself is organized in a specific folder structure

### *Description of the folder structure:*

``"BASE"`` is the main "project" folder. If you want to create another project, copy this folder and rename it to your preference. 
It includes the subfolders ``"Data"`` and ``"Results"``.

``"Data"`` folder contains all the necessary data to run the model. In the subfolder ``"Profiles"``, one can check and modify the wind/solar profiles 
and the electricity prices of different locations for different years. In the subfolder ``"Inputs"``there are excel 
different excel sheets where one can check and modify the input data for different study-case scenarios such as: units conforming for the PtX plant, 
their techno-economic information, the operation strategy of the plant, etc...

``"Results"`` folder has the results/outputs of the simulation. A new folder will be created any time a simulation is run, and
its name would correspond to the one written in the ‘Inputs excel sheet’. Includes different subfolders: Data used,
Hourly results and Main results.


``"CODE"`` includes three Julia scripts named ImportData.jl, ImportScenarios.jl, and Main.jl.


A more detailed description of each folder and their files can (again) be found in the **OPTIPLANT tool-User guide**

### *Filling the 'Inputs' data file:* 

Go to the ``"Inputs"``subfolder and open or create a copy of any of the template files found there. Next, do the following:

a) Fill the ``"Data_base_case"`` sheet with your own techno-economic data (if you changes names in red, it is also necessary to change the 
*Import_data* or *Import_scenarios* julia code files). 

b) In the ``"Selected_units"`` data sheets you can decide to exclude some units from the optimization run (make sure to avoid solving infeasibility by doing so).

c) In the ``"Scenarios_definition"`` sheet, define your scenario(s) name(s) and which data are changed in this scenario compared to the values indicated in the "Data_base_case" sheet.

d) In the ``"ScenariosToRun"`` sheet -create one if needed-, define which scenarios you want to run, the associated profiles, and the assumptions 
(update the name of this excel sheet on the *Main* julia code files if you change its name). 

e) Save all the files you changed.

Additional information about the input data files work is included in the **OptiPlant tool-User guide**

### *Filling the 'Profiles' data file:* 

Go to the ``Profiles"``subfolder (Base > Data > Profiles). There is already some existing profiles and sub-folders that was created for the scientific articles attached to this repository.
Here you can choose open or create a copy of any of the template profile files found there. Then you can change the existing profiles or add new one (by adding an extra column with all the informations filled).

The ``"Flux"`` sheet is for the normalized renewable power profiles (between 0 and 1) and the ``"Price"`` sheet for the electricity spot price.
The Subset indexes and the locations have to match with the ones defined in the 'Inputs' data file (each renewable power technology has its own subset).

Additional information about the profile data files is also included in the **OptiPlant tool-User guide**

### *Run the model and get the results:* 

Go to the ``"Run Code"`` folder and open the ``"Main.jl"`` file and do the following checks/changes:

a) Change the "Main folder" to the correct directory path of your Optiplant folder (make sure the path directories for the other two code files are also correctly written).

b) Choose the "Inputs_file" you want to use (it is also pssible to create your own). For first tests, the "Input_data_example" one is recommended.

c) Choose which scenarios from the "ScenariosToRun" excel sheet (input data) you want to run. You can also use another scenario sheet if it exists (i.e. "Scenarios_sensitivities" if the "Meas_vs_sim_data" is used).

d) Modify the maintenance hours of the plant and the number of working hours for the simulation (max 8760), the currency change, etc. if needed (all input data are currently in €2019).

e) Run the code.


Results appears as CSVs in a result folder previously specified in the ``"Scenarios"`` excel sheet (input data). Running again without changing the destination folder will overwrite the previous results. 
Import the CSV data to the ``"Results_general.xlsm"`` excel file found in the same folder to process and visualize the model outcomes.
