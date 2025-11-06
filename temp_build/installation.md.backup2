# Installation Guide#- Software- Installation



This guide will help you install all the required software and packages to run OptiPlant successfully.This- guide- provides- step-by-step- instructions- for- installing- all- required- software- to- use- OptiPlant.



## Overview##- Julia- Installation



OptiPlant requires:###- Download- Julia

1. **Julia** (programming language and environment)

2. **Visual Studio Code** (code editor with Julia extension)1.- Go- to- https://julialang.org/downloads/

3. **Julia packages** (optimization and data handling libraries)2.- Download- the- Julia- version- corresponding- to- your- operating- system

4. **Microsoft Excel** (for input preparation and results visualization)3.- Run- the- Julia- installer- and- install- the- program



![OptiPlant Installation Overview](images/Fig.15.png)###- Installation- Options



## 1. Julia Installation**Important:**- Tick- the- box- "Add- Julia- to- PATH"- **only- if**- you- already- have- Visual- Studio- Code- installed- on- your- PC.



### Download and Install Julia###- Verification



1. Go to [https://julialang.org/downloads/](https://julialang.org/downloads/)If- the- installation- is- successful,- you- will- see- the- message:- **"You- just- got- Julia- on- your- PC!"**

2. Download the Julia version corresponding to your operating system

*Note:- Examples- in- this- guide- use- Julia- v1.8- environment- as- shown- in- package- manager- prompts.*

![Julia Download Page](images/Fig.3.png)

##- VS- Code- Installation

3. Run the Julia installer and install the program

4. **Important**: Tick the box "Add Julia to PATH" only if you already have Visual Studio Code installed on your PC###- Download- VS- Code



![Julia Installation](images/Fig.4.png)1.- Go- to- https://code.visualstudio.com/Download

2.- Download- the- version- for- your- operating- system

5. If the installation is successful, you will see: "You just got Julia on your PC!"3.- Run- the- installer- and- install- the- program



![Julia Installation Success](images/Fig.5.png)###- Installation- Configuration



### System Requirements**Critical:**- During- installation,- tick- **"Add- to- PATH- (requires- shell- restart)"**



Julia works on:###- Verification

- **Windows**: Windows 10 or later

- **macOS**: macOS 10.14 or later  If- successful,- you- will- see- the- message:- **"You- just- got- VS- Code- on- your- PC!- Next- step- is- to- add- the- corresponding- extensions- and- save- them- in- an- 'environment'."**

- **Linux**: Recent distributions with glibc 2.17 or later

##- VS- Code- Configuration

## 2. Visual Studio Code Installation

###- Install- Julia- Extension

### Download and Install VS Code

1.- Open- VS- Code

1. Go to [https://code.visualstudio.com/Download](https://code.visualstudio.com/Download)2.- Go- to- **View- >- Extensions**- 

2. Download the version for your operating system3.- Search- **"Julia"**

4.- Install- the- Julia- extension

![VS Code Download Page](images/Fig.6.png)

###- Start- Julia- REPL

3. Run the installer and install the program

4. **Important**: During installation, tick "Add to PATH (requires shell restart)"Each- session,- start- the- Julia- REPL- via- Command- Palette:

1.- Press- **Ctrl+Shift+P**

![VS Code Installation Options](images/Fig.7.png)2.- Type- **"Start- Julia"**- or- **"Julia:- Start- REPL"**



5. If successful, you will see: "You just got VS Code on your PC! Next step is to add the corresponding extensions and save them in an 'environment'."The- Julia- extension- integrates- the- REPL- (console)- inside- VS- Code,- enabling- executing- Julia- code- and- interacting- with- the- package- manager.



![VS Code Installation Success](images/Fig.8.png)##- Package- Installation



### Install Julia Extension###- Required- Julia- Packages



1. Open Visual Studio CodeOptiPlant- requires- the- following- packages:

2. Go to **View → Extensions** (or press `Ctrl+Shift+X`)

3. Search for "Julia"-- **JuMP**- -- Formulate- optimization- problems

4. Install the Julia extension (provides Julia language support and REPL)-- **HiGHS**- or- **Gurobi**- -- LP- solvers- (only- one- required)

-- **DataFrames**- -- Structured- data- handling

![Julia Extension Installation](images/Fig.9.png)-- **CSV**- -- Read- CSV- files

-- **XLSX**- -- Read- Excel- .xlsx- files

### Configure Julia in VS Code

**Optional- packages**- for- plotting/visualization:

Each time you start working with Julia:-- Plots

-- StatsPlots- - 

1. Press `Ctrl+Shift+P` to open Command Palette-- PrettyTables

2. Type "Start Julia" or "Julia: Start REPL"

3. This will start the Julia REPL (console) inside VS Code###- Installation- Steps



![Julia REPL in VS Code](images/Fig.10.png)1.- **Enter- Package- Manager**

- - - 

## 3. Julia Packages Installation- - - Press- `]`- in- the- Julia- REPL.- The- prompt- changes- from- `julia>`- to- something- like- `(@v1.8)- pkg>`.



### Enter Package Manager2.- **Activate- Environment**

- - - 

1. In the Julia REPL, press `]` to enter package manager mode- - - ```julia

2. The prompt will change from `julia>` to something like `(@v1.8) pkg>`- - - activate- env

- - - ```

![Package Manager](images/Fig.11.png)- - - 

- - - The- prompt- changes- to- `(env)- pkg>`- and- creates/switches- to- folder- env.

### Create and Activate Environment

3.- **Install- Packages**

1. Type: `activate env`- - - 

2. This creates/switches to a folder called "env"- - - Install- each- package- using- the- `add`- command:

3. The prompt changes to `(env) pkg>`- - - ```julia

- - - add- JuMP

![Activate Environment](images/Fig.12.png)- - - add- HiGHS

- - - add- DataFrames

### Install Required Packages- - - add- CSV

- - - add- XLSX

Install the following packages one by one:- - - ```



```julia4.- **Verify- Installation**

add JuMP        # Optimization modeling- - - 

add HiGHS       # Open-source solver (recommended)- - - Check- installed- packages:

add DataFrames  # Structured data handling- - - ```julia

add CSV         # Read CSV files- - - status

add XLSX        # Read Excel files- - - ```

```- - - 

- - - Run- this- command- after- activating- the- env- environment.

![Installing Packages](images/Fig.13.png)

##- Solver- Setup

### Optional Packages

###- HiGHS- (Recommended- -- Open- Source)

For plotting and visualization (optional):

```juliaHiGHS- is- the- recommended- open-source- solver- for- OptiPlant.

add Plots

add StatsPlots  **Installation:**

add PrettyTables```julia

```add- HiGHS

```

### Verify Installation

No- additional- configuration- required.

Type `status` to check installed packages:

###- Gurobi- (Optional- -- Commercial)

```

(env) pkg> statusGurobi- is- a- faster- alternative- that- provides- the- same- results- as- HiGHS.

```

####- Gurobi- Installation- Steps

This will show all packages installed in your environment.

1.- **Get- License**

## 4. Solver Setup- - - -- Visit- https://www.gurobi.com/- (Downloads- &- Licenses)

- - - -- Register- and- obtain- the- `grbgetkey`

### HiGHS (Recommended - Open Source)

2.- **Install- Gurobi- Optimizer**

HiGHS is the recommended solver for OptiPlant:- - - -- Download- the- latest- optimizer- from- https://www.gurobi.com/downloads/gurobi-optimizer-eula/

- - - -- Install- the- software

```julia

add HiGHS3.- **Restart- System**

```- - - -- Restart- if- not- done- automatically



**Advantages:**4.- **Activate- License**

- Open-source and free- - - -- Open- Command- Prompt

- Fast performance- - - -- Enter- the- saved- key:- `grbgetkey- <your-key>`

- Same results as commercial alternatives- - - -- Save- the- license- in- the- default- location

- No license required

5.- **Install- Julia- Package**

### Gurobi (Optional - Commercial)- - - ```julia

- - - add- Gurobi

If you prefer Gurobi (commercial solver with identical results):- - - ```



1. Get a license at [https://www.gurobi.com/](https://www.gurobi.com/)##- Dependency- Management

2. After registration, obtain the license key

3. Install the Gurobi Optimizer from [https://www.gurobi.com/downloads/gurobi-optimizer-eula/](https://www.gurobi.com/downloads/gurobi-optimizer-eula/)###- Using- Julia- Environments

4. Restart your system if not done automatically

5. Open Command Prompt and enter the license key:OptiPlant- uses- Julia- environments- for- dependency- management:



```bash1.- **Activate- environment**:- `activate- env`

grbgetkey YOUR_LICENSE_KEY2.- **Install- packages**- into- the- activated- environment

```3.- **Check- status**:- `status`- to- verify- packages

4.- **Activate- each- session**:- Remember- to- activate- the- environment- each- time- you- start- Julia

![Gurobi License Setup](images/Fig.14.png)

###- Package- Verification

6. Save the license in the default location

7. In Julia package manager: `add Gurobi`After- installation,- verify- packages- are- available:



**Note**: Both HiGHS and Gurobi provide identical results. HiGHS is recommended as it's open-source.```julia

using- JuMP

## 5. Verification Stepsusing- HiGHS- - #- or- using- Gurobi

using- DataFrames

### Test Julia Installationusing- CSV

using- XLSX

1. Open Julia REPL```

2. Type: `println("Hello OptiPlant!")`

3. You should see the message printed##- Troubleshooting- Installation



### Test Package Installation###- Package- Not- Found- Error



In Julia REPL:**Error:**- `Package- X- not- found`

```julia

using JuMP, HiGHS, DataFrames, CSV, XLSX**Likely- causes:**

println("All packages loaded successfully!")-- Environment- not- activated- before- running- code

```-- Package- not- installed

-- Package- not- called- in- code

### Test VS Code Integration

**Solution:**

1. Create a new file with `.jl` extension1.- In- Julia- REPL,- press- `]`- to- enter- package- manager

2. Write some Julia code2.- Type- `activate- env`

3. Use `Ctrl+Enter` to execute code in the REPL3.- Check- installed- packages- with- `status`

4.- If- missing,- install- with- `add- PACKAGE_NAME`

## Troubleshooting5.- Ensure- code- calls- necessary- packages- at- the- beginning



### Julia Not Recognized###- Installation- Problems



**Problem**: "Julia is not recognized as an internal or external command"**Julia- or- VS- Code- not- recognized:**

-- Ensure- "Add- to- PATH"- options- were- selected- during- installation

**Solution**: -- For- VS- Code:- "Add- to- PATH- (requires- shell- restart)"

- Ensure "Add Julia to PATH" was checked during installation-- For- Julia:- "Add- Julia- to- PATH"- (if- VS- Code- already- installed)

- Restart your computer

- Reinstall Julia with PATH option checked**Gurobi- license- issues:**

-- Ensure- you- ran- `grbgetkey- <your-key>`- in- Command- Prompt

### VS Code Cannot Find Julia-- Save- license- to- default- location

-- Restart- system- after- Gurobi- installation

**Problem**: Julia extension not working properly

##- Next- Steps

**Solution**:

1. Open VS Code Settings (`Ctrl+,`)Once- installation- is- complete:

2. Search for "Julia executable path"

3. Set the correct path to Julia executable1.- **[Download- OptiPlant](usage.md#getting-optiplant)**- -- Get- the- tool- files

4. Restart VS Code2.- **[File- Structure](usage.md)**- -- Understand- the- project- organization- - 

3.- **[Examples](Examples.md)**- -- Start- with- practical- examples

### Package Installation Fails4.- **[Troubleshooting](Examples.md#troubleshooting)**- -- Common- issues- and- solutions


**Problem**: Cannot install packages or dependency errors

**Solution**:
1. Ensure you're in package mode (press `]`)
2. Try: `resolve` then retry installation
3. Update registry: `registry update`
4. Check internet connection

### Environment Issues

**Problem**: Packages not found when running code

**Solution**:
1. Activate the correct environment: `activate env`
2. Verify packages: `status`
3. Ensure your Julia script has `using` statements for required packages

## Next Steps

Once installation is complete:

1. **[Download OptiPlant](https://github.com/njbca/OptiPlant)** - Get the latest version
2. **[Understand File Structure](usage.md)** - Learn the OptiPlant organization
3. **[Run Your First Model](usage.md#running-optiplant)** - Execute a sample case
4. **[Explore Examples](Examples.md)** - Try different scenarios

## System Requirements Summary

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 4 GB | 8 GB+ |
| **Storage** | 2 GB | 5 GB+ |
| **Processor** | Any modern CPU | Multi-core CPU |
| **Operating System** | Windows 10, macOS 10.14, Linux | Latest versions |

**Typical solve time**: Less than 5 minutes on a personal computer using HiGHS solver.

---

**Installation Complete!** You're now ready to use OptiPlant for power-to-X system optimization.