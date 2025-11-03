# OptiPlant.jl Documentation

GitHub Repo: [https://github.com/njbca/OptiPlant](https://github.com/njbca/OptiPlant)

Welcome to OptiPlant.jl! A Julia package for modeling and optimizing Power-to-X fuel production systems with a high variety of customizable input parameters. The tool is adapted to investigate a large number of scenarios and system configurations in a single run.

## Installation

You can install OptiPlant by cloning the repository and activating the project environment:

```julia
# Clone the repository (or use GitHub Desktop)
# git clone https://github.com/njbca/OptiPlant.git

# Navigate to the project directory and activate
using Pkg
Pkg.activate("path/to/OptiPlant")
Pkg.instantiate()
```

followed by

```julia
using OptiPlantPtX
```

to load the package.

## Overview

To start out, let's discuss the high-level functionality provided by the package, which hopefully will help direct you to more specific documentation for your use-case:

• **Power-to-X System Modeling**: Comprehensive modeling capabilities for various P2X fuel production systems including hydrogen, ammonia, and synthetic fuels production chains.

• **Multi-Scenario Analysis**: Built-in support for running and comparing multiple scenarios with different system configurations, locations, and operational parameters.

• **Optimization Engine**: Integration with commercial (Gurobi) and open-source (HiGHS) solvers for linear programming optimization of system design and operation.

• **Dashboard Integration**: Interactive Streamlit dashboards for visualization and analysis of results, including capacity optimization, investment analysis, and daily operational profiles.

• **Flexible Data Input**: Support for various data sources including CSV profiles for renewable energy resources, techno-economic parameters, and LCIA data.

• **Location-Based Analysis**: Pre-configured profiles for multiple locations including Denmark, Antofagasta, Bornholm, and Faroe Islands with corresponding renewable energy resources.

That's quite a bit! Let's boil down a TL;DR:

• Just want to run a basic P2X optimization? Use the main [`Run.jl`] script with default parameters.
• Need to analyze multiple scenarios? Configure your scenarios and use [`Run_multi_scenarios.jl`] or the parallel version.
• Want interactive visualization? Set up the Streamlit dashboards for real-time analysis.
• Need to add new locations or technologies? Modify the data files in the [`data/`] folders following the existing structure.
• Want to understand the model structure? Check out the detailed documentation in the usage section.

For the rest of the manual, we're going to have sections covering [Installation], [Usage], [Examples], and [API Reference] where we'll walk through the various options and configurations available in OptiPlant.jl.

• [Installation] - Detailed setup instructions for Julia, solvers, and dependencies
• [Usage] - Basic to advanced usage patterns and configuration options  
• [Examples] - Practical examples for common use cases and scenarios
• [API Reference] - Complete documentation of functions, types, and modules

## Citation

Please cite the following paper when using OptiPlant in your research:

Campion, N., Barbosa, J., Mohammadi, A., & Lund, H. (2023). Optimization and analysis of large-scale renewable fuel production systems. *Renewable and Sustainable Energy Reviews*, 171, 113057. https://doi.org/10.1016/j.rser.2022.113057
