import os
from pathlib import Path
import pandas as pd
import streamlit as st

# Dashboard_CO2.py
# GitHub Copilot
# Streamlit dashboard to compare scenarios (stacked bars by "Type of unit").
# Adjust column names to match your files if necessary.

import plotly.graph_objects as go
import matplotlib.pyplot as plt
import numpy as np

# ----- Default configuration (adjust if needed) -----
DEFAULT_RESULTS_DIR = r"C:\GitHub\OptiPlant.jl\results\Ammonia_paper\Results_base_case\Main results"
DEFAULT_XLSX = r"C:\GitHub\OptiPlant.jl\data\Ammonia_paper\model_inputs\Data_ammonia_paper.xlsx"
EXCEL_SHEET = "ScenariosToRun"

st.set_page_config(layout="wide", page_title="Dashboard CO2")

st.title("Dashboard CO2 - Compare scenarios by location")

# Sidebar: paths and options
results_dir = Path(st.sidebar.text_input("Results directory", DEFAULT_RESULTS_DIR))
xlsx_path = Path(st.sidebar.text_input("Excel with scenario metadata", DEFAULT_XLSX))
# The scenarios sheet is fixed to 'ScenariosToRun' and its header is on row 7
sheet_name = EXCEL_SHEET

# value_col will be detected from the first scenario CSV when possible and offered as a selectbox below
value_col = None
# Force the unit-type column to a fixed value (not selectable)
type_col = "Type of unit"

# Read Excel with scenario metadata
@st.cache_data
def load_scenarios_table(xlsx_path, sheet_name, header_override=-1):
    # Try to detect the header row dynamically by searching for a row that contains
    # a 'scenario' header (e.g. 'Scenario number', 'Scenario #', 'Scenario').
    # Fallback to header=6 (row 7) if detection fails.
    try:
        raw = pd.read_excel(xlsx_path, sheet_name=sheet_name, header=None, nrows=40)
    except Exception:
        # Fallback to direct read
        raw = None

    header_row = None
    # if user provided an override, use it
    if header_override is not None and header_override >= 0:
        header_row = int(header_override)
    else:
        header_candidates = {"scenario number", "scenario_number", "scenario#", "scenario #", "scenario id", "scenario", "scenario no", "scenario number"}
        if raw is not None:
            for i in range(min(40, raw.shape[0])):
                row_vals = raw.iloc[i].astype(str).str.lower().str.strip().tolist()
                if any(rv in header_candidates for rv in row_vals if rv is not None):
                    header_row = i
                    break

    if header_row is None:
        header_row = 6

    df = pd.read_excel(xlsx_path, sheet_name=sheet_name, header=header_row)
    # Normalize column names to find the important fields: scenario key (for filenames), scenario name, location, fuel
    lc = {c.lower().strip(): c for c in df.columns}

    # Helpers to find columns by keyword candidates
    def find_col(key_candidates):
        for k in key_candidates:
            if k in lc:
                return lc[k]
        return None

    # Scenario key (used to find Scenario_*.csv). Prefer explicit number/id columns, else 'scenario'
    scen_key_col = find_col(["scenario number", "scenario_number", "scenario#", "scenario #", "scenario id", "id", "number"])
    if scen_key_col is None:
        scen_key_col = find_col(["scenario"])

    # Scenario name (human readable)
    scen_name_col = find_col(["scenario name", "scenario_name", "scenario title", "scenario title/name"]) or find_col(["scenario"])
    loc_col = find_col(["location", "place", "site"])
    fuel_col = find_col(["fuel"])
    electrolyser_col = find_col(["electrolyser", "electrolyser type", "electrolyser_name"]) 

    # Rename to standardized internal names
    rename_map = {}
    if scen_key_col is not None:
        rename_map[scen_key_col] = "Scenario_key"
    if scen_name_col is not None and scen_name_col != scen_key_col:
        rename_map[scen_name_col] = "Scenario_name"
    if loc_col is not None:
        rename_map[loc_col] = "Location"
    if fuel_col is not None:
        rename_map[fuel_col] = "Fuel"
    if electrolyser_col is not None:
        rename_map[electrolyser_col] = "Electrolyser"

    df = df.rename(columns=rename_map)

    # Ensure required columns exist
    if "Scenario_key" not in df.columns:
        # fallback: use the first column as key
        df = df.rename(columns={df.columns[0]: "Scenario_key"})
    if "Scenario_name" not in df.columns:
        # if no separate name column, use key as name
        df["Scenario_name"] = df["Scenario_key"].astype(str)
    if "Location" not in df.columns:
        df["Location"] = ""
    if "Fuel" not in df.columns:
        df["Fuel"] = ""

    # Strip whitespace on key string columns
    for c in ["Scenario_key", "Scenario_name", "Location", "Fuel"]:
        if c in df.columns:
            df[c] = df[c].astype(str).str.strip()

    return df

# Load result CSVs per scenario and join with metadata
@st.cache_data
def build_data(results_dir, scenarios_df, type_col, value_col):
    rows = []
    for _, r in scenarios_df.iterrows():
        scnum = r.get("Scenario_key")
        # Try several filename patterns. Handle NaN or non-numeric scenario numbers safely.
        scnum_str = "" if pd.isna(scnum) else str(scnum).strip()
        scnum_int = None
        try:
            # attempt to get an integer version when possible (e.g. '1.0' -> 1)
            if not pd.isna(scnum):
                scnum_int = int(float(scnum))
        except Exception:
            scnum_int = None

        candidates = []
        if scnum_str != "":
            candidates.extend([
                results_dir / f"Scenario_{scnum_str}.csv",
                results_dir / f"Scenario {scnum_str}.csv",
                results_dir / f"Scenario-{scnum_str}.csv",
            ])
        if scnum_int is not None:
            candidates.append(results_dir / f"Scenario_{scnum_int}.csv")
        csv_path = None
        for c in candidates:
            if c.exists():
                csv_path = c
                break
        if csv_path is None:
            # skip if file does not exist
            continue
        try:
            df = pd.read_csv(csv_path)
        except Exception:
            # skip files that fail to read
            continue
        # add metadata for this scenario
        df["_ScenarioNumber"] = scnum
        df["_ScenarioName"] = r.get("Scenario_name", "")
        df["_Location"] = r.get("Location", "")
        df["_Fuel"] = r.get("Fuel", "")
        # include Electrolyser if present in scenarios table
        df["_Electrolyser"] = r.get("Electrolyser", "")
        df["_SourceFile"] = str(csv_path)
        rows.append(df)
    if not rows:
        return pd.DataFrame()
    all_df = pd.concat(rows, ignore_index=True)
    # ensure existence of columns of interest
    if type_col not in all_df.columns:
        all_df[type_col] = "(unknown)"
    if value_col not in all_df.columns:
        # if the value column does not exist, create a zero column to avoid errors
        all_df[value_col] = 0.0
    return all_df

# Load and prepare data (auto-detection only; no manual header override)
try:
    scenarios_df = load_scenarios_table(xlsx_path, sheet_name)
except Exception as e:
    st.error(f"Error reading Excel: {e}")
    st.stop()

# Helper to inspect the sheet and show debug info
def inspect_scenarios_sheet(xlsx_path, sheet_name, max_rows=40):
    try:
        raw = pd.read_excel(xlsx_path, sheet_name=sheet_name, header=None, nrows=max_rows)
    except Exception:
        return None
    header_candidates = {"scenario number", "scenario_number", "scenario#", "scenario #", "scenario id", "scenario", "scenario no"}
    header_row = None
    for i in range(min(max_rows, raw.shape[0])):
        row_vals = raw.iloc[i].astype(str).str.lower().str.strip().tolist()
        if any(rv in header_candidates for rv in row_vals if rv is not None):
            header_row = i
            break
    if header_row is None:
        header_row = 6
    try:
        df_head = pd.read_excel(xlsx_path, sheet_name=sheet_name, header=header_row)
    except Exception:
        df_head = None
    return {"header_row": header_row, "raw": raw, "df_head_columns": list(df_head.columns) if df_head is not None else None}

ins = inspect_scenarios_sheet(xlsx_path, sheet_name)
if ins is not None:
    with st.expander("Debug: ScenariosToRun detection (show)"):
        st.write(f"Detected header_row = {ins['header_row']}")
        st.write("Columns detected when reading with that header:")
        st.write(ins.get('df_head_columns'))
        st.write("Raw rows around header (first 12 rows):")
        st.dataframe(ins['raw'].iloc[0:12])

# Helper: find first existing scenario CSV from the scenarios table
def find_first_csv_path(results_dir, scenarios_df):
    for _, r in scenarios_df.iterrows():
        scnum = r.get("Scenario_key")
        scnum_str = "" if pd.isna(scnum) else str(scnum).strip()
        scnum_int = None
        try:
            if not pd.isna(scnum):
                scnum_int = int(float(scnum))
        except Exception:
            scnum_int = None
        candidates = []
        if scnum_str != "":
            candidates.extend([
                results_dir / f"Scenario_{scnum_str}.csv",
                results_dir / f"Scenario {scnum_str}.csv",
                results_dir / f"Scenario-{scnum_str}.csv",
            ])
        if scnum_int is not None:
            candidates.append(results_dir / f"Scenario_{scnum_int}.csv")
        for c in candidates:
            if c.exists():
                return c
    return None

# Try to detect numeric columns from the first scenario CSV and show them as a selectbox
first_csv = find_first_csv_path(results_dir, scenarios_df)
detected_numeric_cols = []
if first_csv is not None:
    try:
        tmp = pd.read_csv(first_csv, nrows=200)
        # pick numeric columns (exclude index/time-like if obvious)
        numeric_cols = tmp.select_dtypes(include=["number"]).columns.tolist()
        # remove columns that are clearly not per-unit values (Time columns named 'Time' or similar)
        numeric_cols = [c for c in numeric_cols if c.lower() not in ("time", "timestamp")]
        detected_numeric_cols = numeric_cols
    except Exception:
        detected_numeric_cols = []

if detected_numeric_cols:
    # let the user choose which numeric column to use (like the other dashboard)
    value_col = st.sidebar.selectbox("Column with value to stack", detected_numeric_cols, index=0)
else:
    # fallback to free text if detection failed
    value_col = st.sidebar.text_input("Column with value to stack (fallback)", "CO2")

data = build_data(results_dir, scenarios_df, type_col, value_col)
if data.empty:
    st.warning("No result files found. Check paths and filenames.")
    st.stop()

# Prepare aggregated table: include Electrolyser and Fuel so we can bracket by three levels
agg = (
    data.groupby(["_Location", "_ScenarioNumber", "_ScenarioName", "_Electrolyser", "_Fuel", type_col], dropna=False)[value_col]
    .sum()
    .reset_index()
)

# Sort to group by ScenarioNumber and then by Location (scenario-major ordering like CAP.py)
agg["_ScenarioNumber"] = pd.to_numeric(agg["_ScenarioNumber"], errors="coerce").fillna(0)
agg = agg.sort_values(["_ScenarioNumber", "_Location"])

# Create x label: "Location\nScenarioName". If Scenario name is empty, fall back to 'Scenario N'
def make_xlabel(r):
    scen_name = r.get("_ScenarioName", "")
    if scen_name is None or str(scen_name).strip() == "":
        scen_label = f"Scenario {int(r['_ScenarioNumber'])}"
    else:
        scen_label = str(scen_name)
    # For plotting we'll keep the x-label as the scenario name only (brackets show electrolyser/fuel/location)
    return scen_label

agg["_xlabel"] = agg.apply(make_xlabel, axis=1)

# Pivot table (include metadata columns)
pivot = agg.pivot_table(index=["_xlabel", "_ScenarioNumber", "_Electrolyser", "_Fuel", "_Location"], columns=type_col, values=value_col, aggfunc="sum", fill_value=0)
pivot = pivot.reset_index().sort_values(["_ScenarioNumber", "_Location", "_Fuel", "_Electrolyser"])

all_types = [c for c in pivot.columns if c not in ["_xlabel", "_Location", "_ScenarioNumber", "_Electrolyser", "_Fuel"]]
# Start with no technologies selected by default; user adds the technologies they want to see
selected = st.multiselect("Select technologies (Type of unit) to include", all_types, default=[])

# Option: normalize per scenario (e.g. show %)
normalize = st.sidebar.checkbox("Normalize (per scenario -> %)", value=False)

# Chart title input (left) with default
default_title = "Stacked by technologies per scenario/location"
chart_title = st.sidebar.text_input("Chart title (left)", value=default_title)

# If nothing selected yet, show a hint and the tables only
if not selected:
    st.info("No technologies selected. Choose one or more technologies from the multiselect to show the plot.")
    with st.expander("Available technologies"):
        st.write(all_types)
    # show the tables for inspection and stop before plotting
    st.stop()

# Prepare data for plotting: x labels are the ordered location+scenario labels
xlabels = pivot["_xlabel"].tolist()

# If normalize, compute row sums across all types (use only available types)
if normalize:
    row_sums = pivot[[c for c in all_types]].sum(axis=1).replace(0, 1)

# Build stacked bar chart using Matplotlib (CAP.py style)
types_to_plot = selected
num_bars = len(xlabels)
indices = np.arange(num_bars)
bar_width = 0.8

# Prepare data matrix for stacked bars
data_matrix = []
for t in types_to_plot:
    col_vals = pivot[t].values if t in pivot.columns else np.zeros(num_bars)
    if normalize:
        col_vals = col_vals / row_sums
    data_matrix.append(np.array(col_vals, dtype=float))

# Colors
cmap = plt.get_cmap('tab20')
colors = [cmap(i % 20) for i in range(len(types_to_plot))]

fig, ax = plt.subplots(figsize=(max(10, num_bars * 0.25), 6))
bottom = np.zeros(num_bars)
for i, (t, vals) in enumerate(zip(types_to_plot, data_matrix)):
    ax.bar(indices, vals, bar_width, bottom=bottom, label=str(t), color=colors[i], edgecolor='black')
    bottom += vals

ax.set_xlim(-0.5, num_bars - 0.5)
ax.set_ylabel("Share" if normalize else value_col)
# set the title on the left using the sidebar input
ax.set_title(chart_title, loc='left')

# Show xlabels and rotate/reduce fontsize if too crowded
ax.set_xticks(indices)
if num_bars > 20:
    ax.set_xticklabels(xlabels, rotation=45, ha='right', fontsize=8)
else:
    ax.set_xticklabels(xlabels, rotation=0, fontsize=10)

# Draw CAP-style brackets using Matplotlib with three levels: Electrolyser (closest to bars), Fuel, Location (outer)
# Compute positions for each metadata value across the x-axis
electrolysers = pivot["_Electrolyser"].tolist()
fuels = pivot["_Fuel"].tolist()
locations = pivot["_Location"].tolist()

# collect positions per Electrolyser/Fuel/Location
elect_positions = {}
for idx, e in enumerate(electrolysers):
    elect_positions.setdefault(e if e is not None else "", []).append(idx)

fuel_positions = {}
for idx, f in enumerate(fuels):
    fuel_positions.setdefault(f if f is not None else "", []).append(idx)

loc_positions = {}
for idx, loc in enumerate(locations):
    loc_positions.setdefault(loc if loc is not None else "", []).append(idx)

# After plotting, `bottom` contains the totals per bar
max_total = bottom.max() if len(bottom) > 0 else 0.0
pos_range = max_total if max_total > 0 else 1.0
# Reserve negative space below the x-axis for brackets (proportional to positive totals)
neg_space = max(0.14 * pos_range, 1.0)
ymin = -neg_space
top = max_total + 0.06 * pos_range
ax.set_ylim(ymin, top)

def _add_bracket_matplotlib(ax, start, end, y, text, linewidth=1, color='black'):
    # horizontal bracket line at y, vertical ticks up towards the axis
    ax.plot([start - 0.5, end + 0.5], [y, y], color=color, lw=linewidth)
    ax.plot([start - 0.5, start - 0.5], [y, y + 0.02 * pos_range], color=color, lw=linewidth)
    ax.plot([end + 0.5, end + 0.5], [y, y + 0.02 * pos_range], color=color, lw=linewidth)
    mid = (start + end) / 2
    # place text below the bracket (so labels are at the very bottom)
    ax.text(mid, y - 0.01 * pos_range, str(text), ha='center', va='top', fontsize=9, color=color)

# Bracket y positions (inner -> outer): Electrolyser (closest to axis but below), Fuel, Location (farthest down)
y1 = -0.02 * pos_range
y2 = -0.06 * pos_range
y3 = -0.10 * pos_range

# Draw Electrolyser-level brackets (closest to axis)
for e, pos in elect_positions.items():
    start = pos[0]
    end = pos[-1]
    _add_bracket_matplotlib(ax, start, end, y1, e if e != "" else "(no electrolyser)", linewidth=1, color='black')

# Draw Fuel-level brackets
for f, pos in fuel_positions.items():
    start = pos[0]
    end = pos[-1]
    _add_bracket_matplotlib(ax, start, end, y2, f if f != "" else "(no fuel)", linewidth=1, color='gray')

# Draw Location-level brackets (outer, farthest down)
for loc, pos in loc_positions.items():
    start = pos[0]
    end = pos[-1]
    _add_bracket_matplotlib(ax, start, end, y3, loc if loc != "" else "(no location)", linewidth=1, color='dimgray')

# place legend outside the plot to the right
ax.legend(bbox_to_anchor=(1.02, 1), loc='upper left', borderaxespad=0)
# give room on the right for the legend
fig.subplots_adjust(right=0.75)
plt.tight_layout()
st.pyplot(fig)

# Show metadata and aggregated data tables for inspection
with st.expander("Aggregated data (table)"):
    st.dataframe(agg)

with st.expander("Pivot table prepared for plotting"):
    st.dataframe(pivot)

st.caption("")

# How to run this dashboard (PowerShell / Windows):
# From the repository root:
#   streamlit run src/PlotGraphs/Dashboard_CO2.py
# Or using an absolute path:
#   streamlit run "C:\GitHub\OptiPlant.jl\src\PlotGraphs\Dashboard_CO2.py"