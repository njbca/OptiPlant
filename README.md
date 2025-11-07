# OptiPlant

**GitHub Repository:** [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)

[![Julia Version](https://img.shields.io/badge/julia-1.6+-blue.svg)](https://julialang.org)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://njbca.github.io/OptiPlant/)
[![License](https://img.shields.io/github/license/njbca/OptiPlant)](https://github.com/njbca/OptiPlant/blob/main/LICENSE)

**OptiPlant** is a linear optimization model that minimizes the investment and operation costs of a power-to-X (PtX) system powered by wind, solar and/or the electricity grid. Developed by Nicolas Campion (DTU Department of Technology, Management and Economics).


## Overview

OptiPlant operates under a "dynamic power supply and system optimization" approach (DPS-Syst-Opt) with perfect foresight. The model sizes units and schedules hourly mass/energy flows to meet a yearly fuel demand at minimum cost.


**Key Features:**
- **Fast solving**: Typical solving time <5 minutes using open-source solver
- **Modular design**: Easy modification of inputs, objectives, and outputs
- **Simple workflow**: Excel → Julia → CSV/Excel results
- **Multi-fuel support**: NH₃, H₂, MeOH production systems
- **Multi-scenario analysis**: Automated batch processing with results organization

## Quick Start

### 1. Download OptiPlant

```bash
# Download ZIP from GitHub
# Go to: https://github.com/njbca/OptiPlant
# Click "Code → Download ZIP"
# Extract to your preferred location
```

### 2. Install Required Software

**Julia**: https://julialang.org/downloads/
**VS Code**: https://code.visualstudio.com/

**Required Packages:**
```julia
] activate env
add JuMP HiGHS DataFrames CSV XLSX
```

### 3. Run Your First Model

1. Open `RUN CODE/Main.jl` in VS Code
2. Set solver: `solver = "HiGHS"`
3. Configure paths (lines 22-25)
4. Run the file

**Typical solve time: <5 minutes**

## Documentation

- **[Complete Documentation](https://njbca.github.io/OptiPlant/)** - Installation, usage, examples, and API reference
- **[Quick Installation](https://njbca.github.io/OptiPlant/installation.html)** - Software setup guide
- **[File Structure](https://njbca.github.io/OptiPlant/usage.html)** - Understanding OptiPlant organization
- **[Examples & Troubleshooting](https://njbca.github.io/OptiPlant/Examples.html)** - Practical examples and solutions
- **[Technical Reference](https://njbca.github.io/OptiPlant/api.html)** - Detailed specifications

## What OptiPlant Can Do

### Supported Systems
- **Power-to-X fuel production** systems
- **Multi-source power supply**: Wind, solar, electricity grid
- **Multiple fuel types**: Ammonia (NH₃), hydrogen (H₂), methanol (MeOH)
- **Flexible system design**: Storage, conversion, and production units

### Capabilities
- **Techno-economic optimization** with customizable parameters
- **Location assessment** using renewable resource profiles
- **Technology comparison** across different system configurations
- **Sensitivity analysis** with automated scenario processing
- **Results visualization** through Excel dashboards with Pivot Tables
- **Interactive web dashboards** with Streamlit for advanced data exploration

### Optimization Features
- **Linear programming** solved with HiGHS (open-source) or Gurobi (commercial)
- **Perfect foresight** optimization with hourly resolution
- **Annual fuel demand** constraint satisfaction
- **Investment and operational** cost minimization

## Interactive Dashboards

OptiPlant includes **Streamlit-based interactive dashboards** for advanced results visualization and analysis. These web-based tools provide dynamic, interactive exploration of optimization results beyond traditional Excel outputs.

### Available Dashboards

#### 1. **CO2 Dashboard** (`Dashboard_CO2.py`)
- **Primary visualization tool** for scenario comparison by location
- **Stacked bar charts** grouped by technology type
- **Multi-level grouping**: Electrolyser → Fuel → Location
- **Interactive filtering** and data exploration
- **Matplotlib and Plotly integration** for high-quality charts

#### 2. **Daily Series Dashboard** (`Dashboard_Daily.py`)
- **Hourly time series visualization** from flow results
- **Customizable time range selection** (start/end hour)
- **Multi-series plotting** with clean formatting
- **Legend positioning** and auto-scaled axes
- **Ideal for operational analysis** and load profile examination

#### 3. **Scenario Comparison Dashboard** (`Dashboard_Scenarios.py`)
- **Multi-scenario comparative analysis** across key metrics
- **Technology-specific comparisons** (CAPEX, installed capacity, etc.)
- **Stacked bar visualizations** with selective technology filtering
- **Batch scenario processing** from CSV results

### Dashboard Features
- **Web-based interface**: No additional software installation required
- **Real-time interactivity**: Dynamic filtering, zooming, and data selection
- **Professional visualizations**: Publication-ready charts and graphs
- **Flexible data input**: Compatible with OptiPlant CSV outputs
- **Responsive design**: Works on desktop and tablet devices

### Quick Dashboard Setup

```powershell
# Create Python environment and install dependencies
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Launch CO2 Dashboard
streamlit run src/PlotGraphs/Dashboard_CO2.py

# Launch Daily Series Dashboard  
streamlit run src/PlotGraphs/Dashboard_Daily.py

# Launch Scenario Comparison Dashboard
streamlit run src/PlotGraphs/Dashboard_Scenarios.py
```

### Dashboard Requirements
- **Python 3.7+** with pip
- **Dependencies**: Streamlit, Pandas, Matplotlib, NumPy, Plotly
- **Input files**: OptiPlant CSV results and Excel scenario metadata
- **Browser**: Modern web browser for dashboard interface

For detailed dashboard setup and troubleshooting, see [`docs/DASHBOARDS.md`](docs/DASHBOARDS.md).

## File Structure

```
OptiPlant-master/
├── BASE/
│   ├── Data/
│   │   ├── Inputs/           # Excel files: units, economics, scenarios
│   │   └── Profiles/         # Wind/solar profiles, electricity prices
│   └── Results/              # Output folders (auto-created per run)
├── src/
│   └── PlotGraphs/           # Interactive Streamlit dashboards
│       ├── Dashboard_CO2.py         # Primary scenario comparison tool
│       ├── Dashboard_Daily.py       # Hourly time series visualization
│       └── Dashboard_Scenarios.py   # Multi-scenario analysis
├── docs/
│   └── DASHBOARDS.md         # Dashboard setup and troubleshooting guide
├── requirements.txt          # Python dependencies for dashboards
└── RUN CODE/
    ├── ImportData.jl         # Data import functions
    ├── ImportScenarios.jl    # Scenario configuration
    └── Main.jl               # Main optimization model
```

## Scientific Background

OptiPlant is based on peer-reviewed research. For detailed model description, mathematical formulation, and validation:

**Nicolas Campion et al.** (2023). "Techno-economic assessment of green ammonia production with different wind and solar potentials." *Renewable and Sustainable Energy Reviews*, 173, 113057.

- **DOI**: [10.1016/j.rser.2022.113057](https://doi.org/10.1016/j.rser.2022.113057)
- **URL**: https://www.sciencedirect.com/science/article/pii/S1364032122009388

## Installation Requirements

### Software Dependencies
- **Julia 1.6+** (examples use v1.8+)
- **VS Code** with Julia extension
- **Microsoft Excel** (for input preparation and results visualization)
- **Python 3.7+** (optional, for interactive dashboards)

### Julia Packages
- **JuMP**: Optimization modeling
- **HiGHS** or **Gurobi**: Linear programming solvers
- **DataFrames**, **CSV**, **XLSX**: Data handling

### Python Packages (for Dashboards)
- **Streamlit**: Web dashboard framework
- **Pandas**: Data manipulation and analysis
- **Matplotlib**: Static plotting and visualization
- **Plotly**: Interactive plotting (optional)
- **NumPy**: Numerical computing

### System Requirements
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 1GB+ for installation and results
- **OS**: Windows 10+, macOS 10.14+, or recent Linux

## Getting Help

### Documentation
- **[Installation Guide](https://njbca.github.io/OptiPlant/installation.html)** - Step-by-step setup
- **[Usage Guide](https://njbca.github.io/OptiPlant/usage.html)** - File organization and workflow
- **[Troubleshooting](https://njbca.github.io/OptiPlant/Examples.html#troubleshooting)** - Common issues and solutions

### Support Resources
- **GitHub Issues**: [Report bugs or request features](https://github.com/njbca/OptiPlant/issues)
- **Julia Community**: [https://discourse.julialang.org/](https://discourse.julialang.org/)
- **JuMP Documentation**: [https://jump.dev/JuMP.jl/stable/](https://jump.dev/JuMP.jl/stable/)

## Citation

When using OptiPlant in your research, please cite:

```bibtex
@article{campion2023optimization,
  title={Techno-economic assessment of green ammonia production with different wind and solar potentials},
  author={Campion, Nicolas and Nami, H and Swisher, P R and Vang Hendriksen, P and M{\"u}nster, M},
  journal={Renewable and Sustainable Energy Reviews},
  volume={173},
  pages={113057},
  year={2023},
  doi={10.1016/j.rser.2022.113057}
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

OptiPlant is actively developed. Contributions are welcome through:

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Submit** a pull request

For major changes, please open an issue first to discuss proposed modifications.

---

**Quick Links:**
- [Documentation](https://njbca.github.io/OptiPlant/)
- [Installation](https://njbca.github.io/OptiPlant/installation.html)
- [Dashboard Setup Guide](docs/DASHBOARDS.md)
- [Download ZIP](https://github.com/njbca/OptiPlant/archive/refs/heads/main.zip)
- [Issues](https://github.com/njbca/OptiPlant/issues)
- [Contact Authors](mailto:ncampion@protonmail.com)
