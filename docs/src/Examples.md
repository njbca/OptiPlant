# Examples

This page will hold short examples showing how to run a model scenario and how
to open the Streamlit dashboards that accompany the repository.

## Run a single scenario (Julia)

From the repository root in PowerShell:

```powershell
julia --project -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"
# run the main runner (example)
julia --project Run.jl
```

Replace `Run.jl` with the specific runner script you use (e.g. `Run ammonia.jl`) and
ensure Gurobi or HiGHS is available for the solver.

## Run the Streamlit dashboard (Python)

Install Python dependencies (see `requirements.txt` in the repository root):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
streamlit run src/PlotGraphs/Dashboard_CO2.py
```

The dashboard contains a debug expander that shows how the Excel `ScenariosToRun`
sheet is parsed — use that to diagnose missing scenario names or header-row issues.
<!--
Examples.md
Purpose: provide runnable examples and common workflows.
What to fill: replace placeholders with real, minimal examples taken from the codebase
or from small synthetic input files located under `data/`.
-->

# Examples

This page contains example usage of `OptiPlantPtX.jl`. Replace the placeholders below with concrete, runnable examples extracted from your repository.

## Example 1 — Minimal run

Demonstrates how to run a minimal optimization and inspect results.

```julia
using OptiPlantPtX

# Load example input file (adjust the path)
# inputs = OptiPlantPtX.read_inputs("examples/example1.xlsx")

# Run a simple optimization
# result = OptiPlantPtX.solve(inputs)

# Show a short summary
# println(result.summary)
```

## Example 2 — Compare scenarios

Show how to load multiple scenario files and compare outcomes (CAPEX, installed capacity, etc.).

```julia
# Example pseudocode — replace with real API calls
scenarios = ["Scenario_1.csv", "Scenario_2.csv"]
results = [OptiPlantPtX.analyze(s) for s in scenarios]

# build a comparison table
# compare_table = OptiPlantPtX.compare(results, :CAPEX)
```

## Tips

- When posting examples, keep them short and runnable.
- Favor real data files from `data/` when possible, or provide synthetic examples.
