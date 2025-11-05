# API Reference

## OptiPlant Functions

### Main Optimization Model

The core optimization model is implemented in `Main.jl`:

- **Input**: Excel files with unit data, scenarios, and profiles
- **Output**: Optimized system design and operation schedule
- **Solver**: HiGHS (open-source) or Gurobi (commercial)

### Data Import Functions

Located in `ImportData.jl`:

- Load unit parameters from Excel sheets
- Import renewable resource profiles
- Process electricity price data

### Scenario Management

Located in `ImportScenarios.jl`:

- Configure multiple optimization scenarios
- Batch processing capabilities
- Results organization and export

## File Structure

```
OptiPlant/
├── BASE/Data/Inputs/          # Unit parameters and scenarios
├── BASE/Data/Profiles/        # Wind, solar, electricity data
├── BASE/Results/              # Optimization outputs
└── RUN CODE/                  # Julia scripts
    ├── Main.jl               # Main optimization model
    ├── ImportData.jl         # Data loading functions
    └── ImportScenarios.jl    # Scenario configuration
```

## Key Parameters

### Economic Data
- **Investment costs**: $/kW for each technology
- **Operating costs**: $/MWh for operation and maintenance
- **Electricity prices**: $/MWh hourly profiles

### Technical Data  
- **Capacity factors**: Wind and solar resource profiles
- **Efficiency curves**: Power conversion and storage
- **Availability**: Maintenance and operational constraints

## Model Formulation

OptiPlant uses linear programming to minimize total system cost:

**Objective**: Minimize investment cost + operational cost

**Subject to**:
- Energy balance constraints
- Capacity constraints  
- Demand satisfaction
- Resource availability

Detailed mathematical formulation is available in the scientific paper:
[DOI: 10.1016/j.rser.2022.113057](https://doi.org/10.1016/j.rser.2022.113057)