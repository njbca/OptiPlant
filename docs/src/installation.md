# Installation Guide

## Fork the repository

Set up a [GitHub account](https://github.com/signup) and sign-in.
On the online repository, click on **Fork >  Create a new fork** and name it as you wish i.e. `OptiPlantPtX`.

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

![Add_to_PATH](images/VSCode_addtopath.png)

1. Open VS Code  
2. Go to `File > Open Folder` → select your `OptiPlantPtX` folder  

## Setup Julia Environment

Make sure you have the **latest Julia version** installed: [Install Julia](https://julialang.org/install/).

1. Add the *Julia* extension in VS Code using the "Extensions: Marketplace" (access on the square icon on left sidebar of VS Code)

![Julia_extension](images/Julia_extension.png)

2. Open the Julia REPL inside VS Code (the first time opening can take a bit of time):  
   - Option 1, keyboard shortcut: Press `Alt + J` then `Alt + O` 
   - Option 2, open the command palette (`Ctrl+Shift+P`) and run: `Julia: Start REPL`

This is now a condensed version of the [Julia documentation](https://pkgdocs.julialang.org/v1/environments/) to use someone else's project.

3. In the REPL, run this comand to move one directory up (where the folder where `OptiPlantPtX` is located):  
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

7. Done! You can exit the package manager pressing the `Backspace key` and start running the examples.