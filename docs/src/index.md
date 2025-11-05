# OptiPlant Documentation# OptiPlant# OptiPlant



OptiPlant is a linear optimization model that minimizes the investment and operation costs of a power-to-X (PtX) system powered by wind, solar and/or the electricity grid.



![GitHub Download](images/Fig.1.png)GitHub Repo: [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)GitHub Repo: [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)



## Overview



The model operates under a "dynamic power supply and system optimization" approach (DPS-Syst-Opt) with perfect foresight. It sizes units and schedules hourly mass/energy flows to meet a yearly fuel demand at minimum cost.![OptiPlant GitHub Download](images/Fig.1.png)![OptiPlant GitHub Download](images/Fig.1.png)



![System Overview](images/Fig.2.png)*Figure 1: OptiPlant GitHub repository - download via "Code → Download ZIP"**Figure 1: OptiPlant GitHub repository - download via "Code → Download ZIP"*



Typical solving time on a personal computer is usually below 5 minutes using an open-source solver.



## Key Features## Using OptiPlant - Summary/Overview**OptiPlant** is a linear optimization model developed by Nicolas Campion (DTU Department of Technology, Management and Economics) that minimizes the investment and operation costs of a power-to-X (PtX) system powered by wind, solar and/or the electricity grid.



- Linear deterministic programming with perfect foresight

- Supports power supply from wind, solar, and the grid

- Fast solve times (often <5 minutes with open-source solver)OptiPlant is a linear optimization model that minimizes the investment and operation costs of a power-to-X (PtX) system powered by wind, solar and/or the electricity grid. It assumes perfect foresight and operates under a "dynamic power supply and system optimization" approach (DPS-Syst-Opt).## Using OptiPlant - Summary/Overview

- Simple workflow: prepare data in Excel, run Julia code, review results in CSV/Excel



## About OptiPlant

The model sizes units and schedules hourly mass/energy flows to meet a yearly fuel demand at minimum cost.OptiPlant is a linear optimization model that minimizes the investment and operation costs of a power-to-X (PtX) system powered by wind, solar and/or the electricity grid. It assumes perfect foresight and operates under a "dynamic power supply and system optimization" approach (DPS-Syst-Opt).

OptiPlant is developed by Nicolas Campion (DTU Department of Technology, Management and Economics) to model PtX fuel production systems.



### Supported Technologies

- Wind profiles![System Overview](images/Fig.2.png)The model sizes units and schedules hourly mass/energy flows to meet a yearly fuel demand at minimum cost.

- Solar profiles  

- Electricity grid (hourly buy price)*Figure 2: OptiPlant system specifications and optimization objective*



### Fuel Types![System Overview](images/Fig.2.png)

- NH₃ (ammonia)

- H₂ (hydrogen) **Typical solving time**: Usually below 5 minutes using an open-source solver on a personal computer.*Figure 2: OptiPlant system specifications and optimization objective*

- MeOH (methanol)



### Scientific Reference

### Main Purpose and Capabilities**Typical solving time**: Usually below 5 minutes using an open-source solver on a personal computer.

Nicolas Campion et al. "Techno-economic assessment of green ammonia production with different wind and solar potentials." Renewable Sustainable Energy Reviews 173 (2023). DOI: 10.1016/j.rser.2022.113057.



[Link to paper](https://www.sciencedirect.com/science/article/pii/S1364032122009388)
**Purpose**: Minimize annualized system cost while meeting a specified yearly fuel demand.### Main Purpose and Capabilities



**Capabilities**:**Purpose**: Minimize annualized system cost while meeting a specified yearly fuel demand.

- Customize input parameters (techno-economic data, electricity prices, renewable profiles, by-product prices)

- Choose optimization objective, variables, and constraints structure**Capabilities**:

- Flexibly modify inputs and extract results in CSV for post-processing in Excel- Customize input parameters (techno-economic data, electricity prices, renewable profiles, by-product prices)

- Run different scenarios defined in Excel and automatically create a results folder per run- Choose optimization objective, variables, and constraints structure

- Flexibly modify inputs and extract results in CSV for post-processing in Excel

### Key Features and Benefits- Run different scenarios defined in Excel and automatically create a results folder per run



- Linear deterministic programming with perfect foresight### Key Features and Benefits

- Supports power supply from wind, solar, and the grid

- Modularity: input parameters, objective, variables/constraints, and outputs can be modified in a fairly easy way- **Linear deterministic programming** with perfect foresight

- Fast solve times (often <5 minutes with open-source solver)- **Power supply support**: Wind, solar, and grid integration

- Simple workflow: prepare data in Excel, run Julia code, review results in CSV/Excel- **Modularity**: Input parameters, objective, variables/constraints, and outputs can be modified easily

- Documentation and tool available via GitHub ZIP download- **Fast solve times**: Often <5 minutes with open-source solver

- **Simple workflow**: Prepare data in Excel, run Julia code, review results in CSV/Excel

## About OptiPlant- **Documentation and tool**: Available via GitHub ZIP download



### Complete Project Description## About OptiPlant



OptiPlant is a tool developed by Nicolas Campion (DTU Department of Technology, Management and Economics) to model PtX fuel production systems with many customizable inputs and to optimize them under DPS-Syst-Opt.### Complete Project Description



The model minimizes the fuel production cost by managing investments and operation of storage, power-supply, and fuel production units under constraints, with perfect foresight. The main driver is the yearly fuel demand, which must be fulfilled.OptiPlant is a tool developed by Nicolas Campion (DTU Department of Technology, Management and Economics) to model PtX fuel production systems with many customizable inputs and to optimize them under DPS-Syst-Opt.



### What Systems Can Be ModeledThe model minimizes the fuel production cost by managing investments and operation of storage, power-supply, and fuel production units under constraints, with perfect foresight. The main driver is the yearly fuel demand, which must be fulfilled.



- PtX fuel production systems powered by wind, solar, and/or the electricity grid### What Systems Can Be Modeled

- Systems composed of non-electrical and electrical units, storage, power supply, and fuel production units

- **PtX fuel production systems** powered by wind, solar, and/or the electricity grid

### Technologies Supported- **System components**: Non-electrical and electrical units, storage, power supply, and fuel production units



- **Wind** (profiles)### Technologies Supported

- **Solar** (profiles)  

- **Electricity grid** (hourly buy price)- **Wind** (profiles)

- **Storage and other plant units** are modeled; specific technology names are defined via the Excel inputs- **Solar** (profiles)  

- **Electricity grid** (hourly buy price)

### Fuel Types That Can Be Produced- **Storage and other plant units**: Specific technology names are defined via the Excel inputs



Examples mentioned: **NH₃** (ammonia), **H₂** (hydrogen), **MeOH** (methanol). The Selected_units sheet demonstrates how unit selections vary "for each fuel production process - i.e. NH₃, H₂, MeOH, etc."### Fuel Types That Can Be Produced



### Optimization Methods AvailableExamples include:

- **NH₃** (ammonia)

Linear programming (LP) solved with open-source **HiGHS** or the commercial solver **Gurobi**. Either solver can be used; both provide the same results (HiGHS recommended as open-source).- **H₂** (hydrogen)

- **MeOH** (methanol)

### Scientific Background and References

The Selected_units sheet demonstrates how unit selections vary for each fuel production process.

For detailed model description (plant components/structure, mathematical formulation, data sources, and considerations), refer to:

### Optimization Methods Available

**Nicolas Campion et al.** "Techno-economic assessment of green ammonia production with different wind and solar potentials." *Renewable Sustainable Energy Reviews* 173 (2023). ISSN: 1364-0321. DOI: 10.1016/j.rser.2022.113057. 

**Linear programming (LP)** solved with:

**Link**: [https://www.sciencedirect.com/science/article/pii/S1364032122009388](https://www.sciencedirect.com/science/article/pii/S1364032122009388)- **HiGHS** (open-source, recommended)

- **Gurobi** (commercial solver)

## Getting Started

Either solver can be used; both provide the same results (HiGHS recommended as open-source).

1. **[Installation](installation.md)** - Set up Julia, VS Code, and required packages

2. **[File Structure](usage.md)** - Understand the OptiPlant tool organization## Key Features and Benefits

3. **[Examples](Examples.md)** - Learn through practical examples and troubleshooting

4. **[API Reference](api.md)** - Technical details and specifications- **Linear deterministic programming** with perfect foresight

- **Multi-source power supply**: Wind, solar, and grid integration

## Scientific Background- **High modularity**: Easy modification of inputs, objectives, and outputs

- **Fast performance**: Often <5 minutes solve time with open-source solver

For detailed model description (plant components/structure, mathematical formulation, data sources, and considerations), refer to:- **User-friendly workflow**: Excel → Julia → CSV/Excel results

- **Complete documentation**: Available via GitHub with comprehensive user guide

**Nicolas Campion et al.** "Techno-economic assessment of green ammonia production with different wind and solar potentials." *Renewable Sustainable Energy Reviews* 173 (2023).

## Getting Started

- **DOI**: [10.1016/j.rser.2022.113057](https://doi.org/10.1016/j.rser.2022.113057)

- **Link**: https://www.sciencedirect.com/science/article/pii/S13640321220093881. **[Installation](installation.md)** - Set up Julia, VS Code, and required packages

2. **[File Structure](usage.md)** - Understand the OptiPlant tool organization

## Citation3. **[Examples](Examples.md)** - Learn through practical examples and troubleshooting

4. **[API Reference](api.md)** - Technical details and specifications

When using OptiPlant in your research, please cite the above publication.

## Scientific Background

```bibtex

@article{campion2023optimization,For detailed model description (plant components/structure, mathematical formulation, data sources, and considerations), refer to:

  title={Techno-economic assessment of green ammonia production with different wind and solar potentials},

  author={Campion, Nicolas and Nami, H and Swisher, P R and Vang Hendriksen, P and M{\"u}nster, M},**Nicolas Campion et al.** "Techno-economic assessment of green ammonia production with different wind and solar potentials." *Renewable Sustainable Energy Reviews* 173 (2023).

  journal={Renewable and Sustainable Energy Reviews},

  volume={173},- **DOI**: [10.1016/j.rser.2022.113057](https://doi.org/10.1016/j.rser.2022.113057)

  pages={113057},- **Link**: https://www.sciencedirect.com/science/article/pii/S1364032122009388

  year={2023},

  doi={10.1016/j.rser.2022.113057}## Citation

}

```When using OptiPlant in your research, please cite the above publication.



## Additional Resources```bibtex

@article{campion2023optimization,

- **GitHub Repository**: [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)  title={Techno-economic assessment of green ammonia production with different wind and solar potentials},

- **Julia**: https://julialang.org/  author={Campion, Nicolas and Nami, H and Swisher, P R and Vang Hendriksen, P and M{\"u}nster, M},

- **VS Code**: https://code.visualstudio.com/  journal={Renewable and Sustainable Energy Reviews},

- **JuMP**: https://jump.dev/JuMP.jl/stable/  volume={173},

- **HiGHS**: https://highs.dev/  pages={113057},

- **Gurobi**: https://www.gurobi.com/  year={2023},
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
