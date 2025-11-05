# Installation Guide

## Julia Installation

Go to https://julialang.org/downloads/ and download Julia for your operating system.

![Julia Download](images/Fig.3.png)

Run the installer:

![Julia Installer](images/Fig.4.png)

Tick "Add Julia to PATH" if you have VS Code installed.

![Julia Success](images/Fig.5.png)

## VS Code Installation

Download from https://code.visualstudio.com/Download

![VS Code Download](images/Fig.6.png)

Run installer:

![VS Code Installer](images/Fig.7.png)

Important: Tick "Add to PATH":

![VS Code PATH](images/Fig.8.png)

Success message:

![VS Code Success](images/Fig.9.png)

## Julia Extension

Install Julia extension:

![Julia Extension](images/Fig.10.png)

Search and install:

![Extension Install](images/Fig.11.png)

Start Julia REPL with Ctrl+Shift+P:

![Julia REPL](images/Fig.12.png)

## Package Installation

Enter package manager with "]":

![Package Manager](images/Fig.13.png)

Required packages:
```julia
] activate env
add JuMP HiGHS DataFrames CSV XLSX
```

## Gurobi Setup (Optional)

For Gurobi license:

![Gurobi Setup](images/Fig.14.png)

```cmd
grbgetkey [your-key]
```