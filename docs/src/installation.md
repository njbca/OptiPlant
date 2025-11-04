# Software Installation

This guide provides step-by-step instructions for installing all required software to use OptiPlant.

## Julia Installation

### Download Julia

1. Go to https://julialang.org/downloads/
2. Download the Julia version corresponding to your operating system
3. Run the Julia installer and install the program

### Installation Options

**Important:** Tick the box "Add Julia to PATH" **only if** you already have Visual Studio Code installed on your PC.

### Verification

If the installation is successful, you will see the message: **"You just got Julia on your PC!"**

*Note: Examples in this guide use Julia v1.8 environment as shown in package manager prompts.*

## VS Code Installation

### Download VS Code

1. Go to https://code.visualstudio.com/Download
2. Download the version for your operating system
3. Run the installer and install the program

### Installation Configuration

**Critical:** During installation, tick **"Add to PATH (requires shell restart)"**

### Verification

If successful, you will see the message: **"You just got VS Code on your PC! Next step is to add the corresponding extensions and save them in an 'environment'."**

## VS Code Configuration

### Install Julia Extension

1. Open VS Code
2. Go to **View > Extensions** 
3. Search **"Julia"**
4. Install the Julia extension

### Start Julia REPL

Each session, start the Julia REPL via Command Palette:
1. Press **Ctrl+Shift+P**
2. Type **"Start Julia"** or **"Julia: Start REPL"**

The Julia extension integrates the REPL (console) inside VS Code, enabling executing Julia code and interacting with the package manager.

## Package Installation

### Required Julia Packages

OptiPlant requires the following packages:

- **JuMP** - Formulate optimization problems
- **HiGHS** or **Gurobi** - LP solvers (only one required)
- **DataFrames** - Structured data handling
- **CSV** - Read CSV files
- **XLSX** - Read Excel .xlsx files

**Optional packages** for plotting/visualization:
- Plots
- StatsPlots  
- PrettyTables

### Installation Steps

1. **Enter Package Manager**
   
   Press `]` in the Julia REPL. The prompt changes from `julia>` to something like `(@v1.8) pkg>`.

2. **Activate Environment**
   
   ```julia
   activate env
   ```
   
   The prompt changes to `(env) pkg>` and creates/switches to folder env.

3. **Install Packages**
   
   Install each package using the `add` command:
   ```julia
   add JuMP
   add HiGHS
   add DataFrames
   add CSV
   add XLSX
   ```

4. **Verify Installation**
   
   Check installed packages:
   ```julia
   status
   ```
   
   Run this command after activating the env environment.

## Solver Setup

### HiGHS (Recommended - Open Source)

HiGHS is the recommended open-source solver for OptiPlant.

**Installation:**
```julia
add HiGHS
```

No additional configuration required.

### Gurobi (Optional - Commercial)

Gurobi is a faster alternative that provides the same results as HiGHS.

#### Gurobi Installation Steps

1. **Get License**
   - Visit https://www.gurobi.com/ (Downloads & Licenses)
   - Register and obtain the `grbgetkey`

2. **Install Gurobi Optimizer**
   - Download the latest optimizer from https://www.gurobi.com/downloads/gurobi-optimizer-eula/
   - Install the software

3. **Restart System**
   - Restart if not done automatically

4. **Activate License**
   - Open Command Prompt
   - Enter the saved key: `grbgetkey <your-key>`
   - Save the license in the default location

5. **Install Julia Package**
   ```julia
   add Gurobi
   ```

## Dependency Management

### Using Julia Environments

OptiPlant uses Julia environments for dependency management:

1. **Activate environment**: `activate env`
2. **Install packages** into the activated environment
3. **Check status**: `status` to verify packages
4. **Activate each session**: Remember to activate the environment each time you start Julia

### Package Verification

After installation, verify packages are available:

```julia
using JuMP
using HiGHS  # or using Gurobi
using DataFrames
using CSV
using XLSX
```

## Troubleshooting Installation

### Package Not Found Error

**Error:** `Package X not found`

**Likely causes:**
- Environment not activated before running code
- Package not installed
- Package not called in code

**Solution:**
1. In Julia REPL, press `]` to enter package manager
2. Type `activate env`
3. Check installed packages with `status`
4. If missing, install with `add PACKAGE_NAME`
5. Ensure code calls necessary packages at the beginning

### Installation Problems

**Julia or VS Code not recognized:**
- Ensure "Add to PATH" options were selected during installation
- For VS Code: "Add to PATH (requires shell restart)"
- For Julia: "Add Julia to PATH" (if VS Code already installed)

**Gurobi license issues:**
- Ensure you ran `grbgetkey <your-key>` in Command Prompt
- Save license to default location
- Restart system after Gurobi installation

## Next Steps

Once installation is complete:

1. **[Download OptiPlant](usage.md#getting-optiplant)** - Get the tool files
2. **[File Structure](usage.md)** - Understand the project organization  
3. **[Examples](Examples.md)** - Start with practical examples
4. **[Troubleshooting](Examples.md#troubleshooting)** - Common issues and solutions