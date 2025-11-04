# OptiPlant

GitHub Repo: [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)

**OptiPlant** is a linear optimization model developed by Nicolas Campion (DTU Department of Technology, Management and Economics) that minimizes the investment and operation costs of a power-to-X (PtX) system powered by wind, solar and/or the electricity grid.

## Summary

OptiPlant operates under a "dynamic power supply and system optimization" approach (DPS-Syst-Opt) with perfect foresight. The model sizes units and schedules hourly mass/energy flows to meet a yearly fuel demand at minimum cost.

**Key characteristics:**
- **Fast solving**: Typical solving time on a personal computer is usually below 5 minutes using an open-source solver
- **Linear deterministic programming** with perfect foresight
- **Modular design**: Input parameters, objective, variables/constraints, and outputs can be modified easily
- **Simple workflow**: Prepare data in Excel, run Julia code, review results in CSV/Excel

## Main Purpose and Capabilities

### Purpose
Minimize annualized system cost while meeting a specified yearly fuel demand.

### Capabilities
- **Customize input parameters**: Techno-economic data, electricity prices, renewable profiles, by-product prices
- **Choose optimization objective**: Variables and constraints structure
- **Flexible modification**: Modify inputs and extract results in CSV for post-processing in Excel
- **Multi-scenario analysis**: Run different scenarios defined in Excel with automatic results folder creation per run

### Supported Systems
- **PtX fuel production systems** powered by wind, solar, and/or the electricity grid
- **System components**: Non-electrical and electrical units, storage, power supply, and fuel production units

### Fuel Types
Examples include:
- **NH₃** (ammonia)
- **H₂** (hydrogen) 
- **MeOH** (methanol)

### Technologies Supported
- **Wind** power (via profiles)
- **Solar** power (via profiles)
- **Electricity grid** (hourly buy price)
- **Storage systems** and other plant units (defined via Excel inputs)

### Optimization Methods
- **Linear programming (LP)** solved with:
  - **HiGHS** (recommended open-source solver)
  - **Gurobi** (commercial solver alternative)
- Both solvers provide identical results
• Want to understand the model structure? Check out the detailed documentation in the usage section.

## Key Features and Benefits

- ✅ **Linear deterministic programming** with perfect foresight
- ✅ **Multi-source power supply**: Wind, solar, and grid integration
- ✅ **High modularity**: Easy modification of inputs, objectives, and outputs
- ✅ **Fast performance**: Often <5 minutes solve time with open-source solver
- ✅ **User-friendly workflow**: Excel → Julia → CSV/Excel results
- ✅ **Complete documentation**: Available via GitHub with comprehensive user guide

## Getting Started

1. **[Installation](installation.md)** - Set up Julia, VS Code, and required packages
2. **[File Structure](usage.md)** - Understand the OptiPlant tool organization
3. **[Examples](Examples.md)** - Learn through practical examples and troubleshooting
4. **[API Reference](api.md)** - Technical details and specifications

## Scientific Background

For detailed model description (plant components/structure, mathematical formulation, data sources, and considerations), refer to:

**Nicolas Campion et al.** "Techno-economic assessment of green ammonia production with different wind and solar potentials." *Renewable Sustainable Energy Reviews* 173 (2023). 

- **DOI**: [10.1016/j.rser.2022.113057](https://doi.org/10.1016/j.rser.2022.113057)
- **Link**: https://www.sciencedirect.com/science/article/pii/S1364032122009388

## Citation

When using OptiPlant in your research, please cite the above publication.

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

## Additional Resources

- **GitHub Repository**: [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)
- **Julia**: https://julialang.org/
- **VS Code**: https://code.visualstudio.com/
- **JuMP**: https://jump.dev/JuMP.jl/stable/
- **HiGHS**: https://highs.dev/
- **Gurobi**: https://www.gurobi.com/
