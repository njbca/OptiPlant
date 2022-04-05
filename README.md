# OptiPlant

Model to optimize the operation and investment of an e-ammonia plant.
The plant can be powered by solar, wind or the grid. 

How to use it:

1- Download the all github folder

2- Download all the necessary Julia packages: ExcelReaders, JuMP, Gurobi, CSV, DataFrames. Another solver may be used.
3- Go to the "Base/Data/Profile" folder
4- Here you can define the normalized power profiles for a specific location and the hourly grid electricity prices.

5- Go to the "Base/Data/Input" folder and open the Base_All_data.xls file
6- Fill the "Data_base_case" sheet with your own techno-economic data
7- In the "Scenarios_definition" sheet, define your scenario name and which data are changed in this scenario compared to the values indicated in the "Data_base_case" sheet
8- In the "Scenarios" sheet, define which scenarios you want to run and the assumptions
9- Save all the files you changed

10- Go to the code folder and open the "Main file"
11- In the problem set up section change the "Main folder" to the path of the Optiplant folder
12- Define which scenarios from the "Scenarios" sheet you want to run
13- Set the maintenance hours of the plant, the starting time and the number of hours for the simulation (max 8760)
14- Choose the currency change if needed
15-Run

16-Results appears as CSVs in a result folder
