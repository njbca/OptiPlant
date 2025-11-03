# Installation

This guide will walk you through setting up OptiPlant.jl locally, configuring your environment, and preparing for your first run.

## Prerequisites

### Julia Installation

Make sure you have the **latest Julia version** installed (≥ 1.11.6): [Install Julia](https://julialang.org/install/).

When installing Julia on Windows, make sure to select the "Add to PATH" option.

### Git Client

Set up a [GitHub account](https://github.com/signup) and install a Git client:
- [GitHub Desktop](https://desktop.github.com/) (recommended for beginners)  
- [Git](https://git-scm.com/downloads) (command line)

### Development Environment (Recommended)

Download and install [Visual Studio Code](https://code.visualstudio.com/) with the Julia extension for the best development experience.

## Installation Methods

### Method 1: Clone Repository (Recommended)

#### Using GitHub Desktop:
1. On the OptiPlant.jl GitHub page, click the green **"<> Code"** button and copy the HTTPS URL
2. In GitHub Desktop: `File > Clone repository`
3. Go to the URL tab and paste the OptiPlant.jl repository URL
4. Choose a local path: **⚠️ Avoid installing on OneDrive/Google Drive as this may cause problems!**

#### Using Command Line:
```bash
git clone https://github.com/njbca/OptiPlant.git
cd OptiPlant
```

### Method 2: Download ZIP (Alternative)
1. Go to the OptiPlant.jl GitHub repository
2. Click **"<> Code" > "Download ZIP"**
3. Extract to your desired location (avoid cloud storage folders)

## Environment Setup

### Open Project in VS Code
1. Open Visual Studio Code
2. `File > Open Folder` → select your `OptiPlant` folder
3. Install the Julia extension from the Extensions Marketplace if not already installed

### Julia Environment Configuration

1. **Open Julia REPL in VS Code:**
   - Press `Alt + J` then `Alt + O` (the first time may take a moment)

2. **Navigate and activate the project:**
   ```julia
   # If needed, navigate to the project directory
   cd("path/to/OptiPlant")  # adjust path as needed
   
   # Enter package manager mode
   ]
   
   # Activate the project environment
   activate .
   
   # Install all dependencies
   instantiate
   
   # Exit package manager mode
   # Press Backspace key
   ```

3. **Verify installation:**
   ```julia
   using OptiPlantPtX
   # Should load without errors
   ```

## Solver Installation

OptiPlant.jl supports both commercial and open-source optimization solvers:

### HiGHS (Open Source - Default)
HiGHS is installed automatically with the Julia dependencies. No additional setup required.

### Gurobi (Commercial - Optional but Recommended)

For better performance with large models:

1. **Install Gurobi software:** 
   - Download from [Gurobi Downloads](https://www.gurobi.com/downloads/)
   - Follow the installation wizard

2. **Activate license:**
   ```bash
   # Academic users can get a free license
   grbgetkey YOUR_LICENSE_KEY
   ```

3. **Verify in Julia:**
   ```julia
   using Gurobi
   # Should load without errors if properly installed
   ```

**Note:** You may need to update Gurobi periodically and regenerate your license to avoid compatibility issues.

## Verification

### Test Installation
1. Open `examples/Run.jl` in VS Code
2. If using HiGHS instead of Gurobi, ensure the solver is set to `"HiGHS"` in the configuration
3. Run the file by clicking the play button (▶️) at the top of VS Code

If no errors appear, congratulations! Your installation is complete.

### Build Documentation Locally (Optional)

To build and view the documentation locally:

```powershell
# From PowerShell in the project root
julia --project=docs -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
julia --project=docs docs/make.jl
```

The documentation will be built in `docs/build/`.

## Troubleshooting

### Common Issues

**"Cannot find OptiPlantPtX"**
- Ensure you've activated the correct project environment with `] activate .`
- Verify you're in the correct directory with the `Project.toml` file

**"Gurobi license issues"** 
- Check your license is still valid: `grbgetkey --help`
- For academic licenses, they typically need renewal annually

**"Package dependencies failed"**
- Try: `] resolve` followed by `] instantiate`
- On Windows, ensure Julia has proper permissions

**"Git/GitHub issues"**
- Avoid spaces in folder paths
- Don't install in OneDrive, Google Drive, or similar cloud storage
- Ensure you have proper permissions for the installation directory

### Getting Help

- Check the [GitHub Issues](https://github.com/njbca/OptiPlant/issues) page
- Contact the maintainers for contribution guidelines
- Review the [Usage Guide](usage.md) for configuration options

## Next Steps

Once installation is complete:
- Read the [Usage Guide](usage.md) to understand basic operations
- Explore the [Examples](Examples.md) for practical use cases
- Review the [API Reference](api.md) for detailed function documentation