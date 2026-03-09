# =============================================
# Scenario Comparison Dashboard (Stacked Bars)
# =============================================

import os
from pathlib import Path
import io
import hashlib
from typing import Dict, List

import pandas as pd
import matplotlib.pyplot as plt
import streamlit as st
from matplotlib.colors import to_rgb

# ------------------------
# Page config
# ------------------------
st.set_page_config(page_title="Scenario Comparison - Stacked Bars", layout="wide")
st.title("Scenario Comparison - Stacked Bar Chart")

# Result folder (adjust if needed)
main_results_folder = Path.cwd() / "results" / "Full_model" / "GLS_analysis" / "Main results"

# ------------------------
# Publication-grade palette
# Color-vision friendly, print-ready, distinct by family.
# ------------------------
TECH_COLORS: Dict[str, str] = {
    # --- Biogas chain (greens; olive–forest range) ---
    "Biogas1": "#6DAF62",
    "Membrane upgrading": "#197219",
    "MeOH plant - biogas": "#032803",
    "Biogas2": "#6DAF62",
    "MeOH plant - biogasdirect": "#3C943C",
    "Biogas3": "#6DAF62",
    "CH4 plant": "#2C7F2C",

    # --- CO2 capture / MeOH from CO2 (yellows distinct from PV bright yellow) ---
    "CO2 capture DAC": "#FFE08A",
    "CO2 capture PS":  "#F0C341",
    "MeOH plant - CO2": "#FFC20A",

    # --- Biomass & biochar (greens; slightly cooler than biogas) ---
    "Biomass wood": "#6FAB67",
    "MeOH plant - biomass": "#4D9C4D",
    "Sale of biochar - biofuel": "#3A7C3A",
    "Biomass straw": "#85BB7C",
    "Biomass - Pyrolysis Unit": "#73B269",
    "Biofuel upgrading unit": "#5EA65A",
    "Sale of biochar DME": "#2D6B2D",

    # --- Biomass feedstocks (light earthy neutrals) ---
    "Biomass bamboo 1": "#E9D7C1",
    "Biomass bamboo 2": "#E1CCB3",
    "Biomass wheat 1":  "#F1DFC8",
    "Biomass wheat 2":  "#E9D4B8",

    # --- SOEC HI biomass variants (saturated greens) ---
    "Bamboo1-stage-SOEC (HI)": "#52A252",
    "Bamboo2-stage-SOEC (HI)": "#469647",
    "Wheat1-stage-SOEC (HI)":  "#5AAA5A",
    "Wheat2-stage-SOEC (HI)":  "#4E9C4F",

    # --- Ammonia + ASU (bluish‑green distinct from olive biomass) ---
    "NH3 plant + ASU - AEC (A)": "#009E73",
    "NH3 plant + ASU - Mix/SOEC (HI)": "#1F9F78",

    # --- Hydrogen end‑use & pipelines (blue‑grey) ---
    "H2 client": "#6C93BD",
    "H2 pipeline to end-user": "#7FA3CA",

    # --- Electrolyzers (greys; clear lightness steps) ---
    "Electrolysers AEC": "#B3B3B3",
    "Electrolysers SOEC heat integrated (HI)": "#E0E0E0",
    "Electrolysers SOEC (A)": "#C8C8C8",
    "Electrolysers Mix 75AEC-25SOEC (HI)": "#D4D4D4",
    "Electrolysers Mix 75AEC-25SOEC (A)":  "#BEBEBE",

    # --- Oxygen byproduct (magenta accent) ---
    "Sale of oxygen": "#CC79A7",

    # --- Water systems (TEAL family; desal red kept as accent) ---
    "Desalination plant": "#D81B60",
    "Waste water plant":   "#1FA4A9",
    "Drinking water":      "#66C2B7",

    # --- Heat links (warm neutrals) ---
    "Heat from district heating": "#C9A26B",
    "Heat sent to district heating": "#B98E55",
    "Heat sent to other process":   "#A6793F",

    # --- H2 storage & balance-of-plant (deep navy family) ---
    "H2 tank compressor":  "#214F78",
    "H2 tank valve":       "#2A5C88",
    "H2 tank":             "#316A99",
    "H2 pipes compressor": "#1A4670",
    "H2 pipes valve":      "#1E527F",
    "H2 buried pipes":     "#193E6A",

    # --- Solar (bright yellows; fixed vs tracking split by lightness) ---
    "Solar fixed":   "#F7D24B",
    "Solar tracking":"#FFC20A",

    # --- Wind ON (sky blues; HH150 lighter than HH100) ---
    "ON_SP198-HH100": "#4EA5D9",
    "ON_SP237-HH100": "#4EA5D9",
    "ON_SP277-HH100": "#4EA5D9",
    "ON_SP321-HH100": "#4EA5D9",
    "ON_SP198-HH150": "#A9D6F5",
    "ON_SP237-HH150": "#A9D6F5",
    "ON_SP277-HH150": "#A9D6F5",
    "ON_SP321-HH150": "#A9D6F5",

    # --- Wind OFF (deeper blues) ---
    "OFF_SP379-HH100": "#2E73B5",
    "OFF_SP450-HH100": "#2E73B5",
    "OFF_SP379-HH150": "#7AAED6",
    "OFF_SP450-HH150": "#7AAED6",

    # --- CSP & TES (orange family; distinct from magenta & red) ---
    "CSP Plant tower 50 MW":      "#E6901D",
    "CSP Plant tower 100 MW":     "#D87E00",
    "CSP Plant parabolic 50 MW":  "#F0A241",
    "CSP Plant parabolic 100 MW": "#E8912B",
    "Charge TES":    "#F3A86A",
    "Discharge TES": "#D9711F",
    "TES ST 50 MW":  "#F09A4A",
    "TES ST 100 MW": "#E58A35",
    "TES PT 50 MW":  "#F09A4A",
    "TES PT 100 MW": "#E58A35",
    "CSP+TES": "#C96E1C",

    # --- Grid, curtailment, batteries (greys; separated by lightness) ---
    "Electricity from the grid": "#5F5F5F",
    "Curtailment":               "#8C8C8C",
    "Charge batteries":    "#CFCFCF",
    "Discharge batteries": "#BDBDBD",

    # UPDATED default color for Batteries (same as Hourly Dashboard)
    "Batteries":           "#E323C6",
}

# Aliases → canonical labels
ALIASES = {
    "MeOH plant - biogas direct": "MeOH plant - biogasdirect",
    # Electrolyzers
    "Electrolyser": "Electrolysers AEC",
    "Electrolysers": "Electrolysers AEC",
    "Electrolyser AEC": "Electrolysers AEC",
    "Electrolyzer AEC": "Electrolysers AEC",
    "SOEC (A)": "Electrolysers SOEC (A)",
    "SOEC HI": "Electrolysers SOEC heat integrated (HI)",
    # Wind variations
    "ON SP198-HH100": "ON_SP198-HH100",
    "ON SP237-HH100": "ON_SP237-HH100",
    "ON SP277-HH100": "ON_SP277-HH100",
    "ON SP321-HH100": "ON_SP321-HH100",
    "ON SP198-HH150": "ON_SP198-HH150",
    "ON SP237-HH150": "ON_SP237-HH150",
    "ON SP277-HH150": "ON_SP277-HH150",
    "ON SP321-HH150": "ON_SP321-HH150",
    "OFF SP379-HH100": "OFF_SP379-HH100",
    "OFF SP450-HH100": "OFF_SP450-HH100",
    "OFF SP379-HH150": "OFF_SP379-HH150",
    "OFF SP450-HH150": "OFF_SP450-HH150",
    # Solar
    "PV fixed": "Solar fixed",
    "PV tracking": "Solar tracking",
    # Grid
    "Grid": "Electricity from the grid",
    "Grid power": "Electricity from the grid",
    "Electricity grid": "Electricity from the grid",
    # Batteries
    "Battery": "Batteries",
    "Battery storage": "Batteries",
    # Water
    "Wastewater plant": "Waste water plant",
    "Drinking-water": "Drinking water",
    # CO2 capture short forms
    "DAC": "CO2 capture DAC",
    "Post-combustion capture": "CO2 capture PS",
}

def normalize_label(label: str) -> str:
    return ALIASES.get(str(label).strip(), str(label).strip())

# ------------------------
# Group map
# ------------------------
GROUP_MAP: Dict[str, str] = {
    # Biogas & methanol from biogas
    "Biogas1": "Biogas & MeOH (biogas)",
    "Membrane upgrading": "Biogas & MeOH (biogas)",
    "MeOH plant - biogas": "Biogas & MeOH (biogas)",
    "Biogas2": "Biogas & MeOH (biogas)",
    "MeOH plant - biogasdirect": "Biogas & MeOH (biogas)",
    "Biogas3": "Biogas & MeOH (biogas)",
    "CH4 plant": "Biogas & MeOH (biogas)",

    # CO2 capture & MeOH from CO2
    "CO2 capture DAC": "CO2 capture & MeOH (CO2)",
    "CO2 capture PS":  "CO2 capture & MeOH (CO2)",
    "MeOH plant - CO2": "CO2 capture & MeOH (CO2)",

    # Biomass & biochar
    "Biomass wood": "Biomass & biochar",
    "MeOH plant - biomass": "Biomass & biochar",
    "Sale of biochar - biofuel": "Biomass & biochar",
    "Biomass straw": "Biomass & biochar",
    "Biomass - Pyrolysis Unit": "Biomass & biochar",
    "Biofuel upgrading unit": "Biomass & biochar",
    "Sale of biochar DME": "Biomass & biochar",

    # Biomass feedstocks
    "Biomass bamboo 1": "Biomass feedstocks",
    "Biomass bamboo 2": "Biomass feedstocks",
    "Biomass wheat 1":  "Biomass feedstocks",
    "Biomass wheat 2":  "Biomass feedstocks",

    # SOEC HI variants
    "Bamboo1-stage-SOEC (HI)": "Biomass SOEC (HI)",
    "Bamboo2-stage-SOEC (HI)": "Biomass SOEC (HI)",
    "Wheat1-stage-SOEC (HI)":  "Biomass SOEC (HI)",
    "Wheat2-stage-SOEC (HI)":  "Biomass SOEC (HI)",

    # Ammonia
    "NH3 plant + ASU - AEC (A)": "Ammonia + ASU",
    "NH3 plant + ASU - Mix/SOEC (HI)": "Ammonia + ASU",

    # Hydrogen demand & pipelines
    "H2 client": "Hydrogen end-use & transport",
    "H2 pipeline to end-user": "Hydrogen end-use & transport",

    # Electrolyzers
    "Electrolysers AEC": "Electrolyzers",
    "Electrolysers SOEC heat integrated (HI)": "Electrolyzers",
    "Electrolysers SOEC (A)": "Electrolyzers",
    "Electrolysers Mix 75AEC-25SOEC (HI)": "Electrolyzers",
    "Electrolysers Mix 75AEC-25SOEC (A)": "Electrolyzers",

    # Oxygen byproduct
    "Sale of oxygen": "Oxygen byproduct",

    # Water systems
    "Desalination plant": "Water systems",
    "Waste water plant":  "Water systems",
    "Drinking water":     "Water systems",

    # Heat links
    "Heat from district heating": "Heat links",
    "Heat sent to district heating": "Heat links",
    "Heat sent to other process":   "Heat links",

    # H2 storage & BoP
    "H2 tank compressor":  "H2 storage & BoP",
    "H2 tank valve":       "H2 storage & BoP",
    "H2 tank":             "H2 storage & BoP",
    "H2 pipes compressor": "H2 storage & BoP",
    "H2 pipes valve":      "H2 storage & BoP",
    "H2 buried pipes":     "H2 storage & BoP",

    # Solar PV
    "Solar fixed":   "Solar PV",
    "Solar tracking":"Solar PV",

    # Wind
    "ON_SP198-HH100": "Onshore wind",
    "ON_SP237-HH100": "Onshore wind",
    "ON_SP277-HH100": "Onshore wind",
    "ON_SP321-HH100": "Onshore wind",
    "ON_SP198-HH150": "Onshore wind",
    "ON_SP237-HH150": "Onshore wind",
    "ON_SP277-HH150": "Onshore wind",
    "ON_SP321-HH150": "Onshore wind",
    "OFF_SP379-HH100": "Offshore wind",
    "OFF_SP450-HH100": "Offshore wind",
    "OFF_SP379-HH150": "Offshore wind",
    "OFF_SP450-HH150": "Offshore wind",

    # CSP & TES
    "CSP Plant tower 50 MW":      "CSP",
    "CSP Plant tower 100 MW":     "CSP",
    "CSP Plant parabolic 50 MW":  "CSP",
    "CSP Plant parabolic 100 MW": "CSP",
    "CSP+TES": "CSP",
    "Charge TES": "TES",
    "Discharge TES": "TES",
    "TES ST 50 MW": "TES",
    "TES ST 100 MW": "TES",
    "TES PT 50 MW": "TES",
    "TES PT 100 MW": "TES",

    # Grid & curtailment
    "Electricity from the grid": "Grid & curtailment",
    "Curtailment": "Grid & curtailment",

    # Batteries
    "Charge batteries": "Batteries",
    "Discharge batteries": "Batteries",
    "Batteries": "Batteries",
}

def get_group(tech: str) -> str:
    return GROUP_MAP.get(tech, "Other")

# ------------------------
# Utility helpers
# ------------------------
def stable_color_from_name(name: str) -> str:
    """Generate a stable hex color for a given name across runs."""
    h = hashlib.md5(str(name).encode("utf-8")).hexdigest()[:6]
    return f"#{int(h, 16):06x}"

def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def relative_luminance_hex(hex_color: str) -> float:
    """WCAG relative luminance (0..1)."""
    r, g, b = to_rgb(hex_color)
    R = _srgb_to_linear(r)
    G = _srgb_to_linear(g)
    B = _srgb_to_linear(b)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B

def edge_for_fill(hex_color: str) -> str:
    """Choose white or dark edge depending on fill lightness for crisp separation."""
    L = relative_luminance_hex(hex_color)
    return "#222222" if L > 0.72 else "#FFFFFF"

@st.cache_data(show_spinner=False)
def load_csv(path: str) -> pd.DataFrame:
    """Load a CSV with basic robustness."""
    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]
    return df

# ------------------------
# File discovery
# ------------------------
csv_files: List[str] = []
if main_results_folder:
    folder_path = Path(main_results_folder)
    if folder_path.exists() and folder_path.is_dir():
        csv_files = sorted(
            [f for f in os.listdir(folder_path)
             if f.lower().startswith("scenario") and f.lower().endswith(".csv")]
        )
        if csv_files:
            st.success(f"Found {len(csv_files)} scenario CSV files in the folder.")
        else:
            st.info("No files found matching 'scenario*.csv' in this folder.")
    else:
        st.warning("The provided folder path does not exist or is not a directory.")

# ------------------------
# Sidebar controls
# ------------------------
st.sidebar.title("Scenario Options")
selected_files = st.sidebar.multiselect("Select scenarios:", csv_files, default=[])

dfs: Dict[str, pd.DataFrame] = {}
for file in selected_files:
    path = os.path.join(main_results_folder, file)
    try:
        dfs[file] = load_csv(path)
    except Exception as e:
        st.sidebar.error(f"Failed to read {file}: {e}")

# Find common columns
if dfs:
    common_cols = set.intersection(*(set(df.columns) for df in dfs.values()))
else:
    common_cols = set()

# Filter non-numeric
exclude_name_parts = ["id", "name", "site", "scenario"]
exclude_cols = {col for col in common_cols if any(x in col.lower() for x in exclude_name_parts)}

def is_numeric_in_all(col: str) -> bool:
    try:
        return all(pd.api.types.is_numeric_dtype(df[col]) for df in dfs.values())
    except Exception:
        return False

candidate_cols = [c for c in common_cols if c not in exclude_cols]
compare_cols = sorted([c for c in candidate_cols if is_numeric_in_all(c)])

if compare_cols:
    selected_col = st.sidebar.selectbox(
        "Select result to compare across scenarios:",
        compare_cols, index=0)
else:
    selected_col = None
    st.sidebar.info("No common numeric columns found to compare.")

# Technology column detection
tech_col = None
for c in ["Type of unit", "Type of unit\n", "Technology"]:
    if dfs and all(c.strip() in df.columns for df in dfs.values()):
        tech_col = c.strip()
        break

# ------------------------
# Scenario names
# ------------------------
def choose_scenario_name(df: pd.DataFrame, fallback: str) -> str:
    if df is not None and "Scenario" in df.columns:
        s = df["Scenario"].dropna().astype(str).str.strip()
        s = s[s != ""]
        if not s.empty:
            try:
                return s.mode().iloc[0]
            except Exception:
                return s.iloc[0]
    return fallback

def deduplicate_labels(labels: List[str]) -> List[str]:
    seen = {}
    out = []
    for lab in labels:
        if lab not in seen:
            seen[lab] = 1
            out.append(lab)
        else:
            seen[lab] += 1
            out.append(f"{lab} ({seen[lab]})")
    return out

scenario_name_map: Dict[str, str] = {}
proposed = []
for file in selected_files:
    df_here = dfs.get(file)
    fallback = Path(file).stem
    proposed.append(choose_scenario_name(df_here, fallback))

unique_labels = deduplicate_labels(proposed)
for file, label in zip(selected_files, unique_labels):
    scenario_name_map[file] = label

# ------------------------
# Build tech × scenario data
# ------------------------
if not selected_files:
    st.info("Select scenarios and technologies to compare.")
    st.stop()

if not selected_col:
    st.warning("Please select a numeric column to compare.")
    st.stop()

techs = set()
if dfs:
    if tech_col:
        for df in dfs.values():
            vals = df[tech_col].dropna().astype(str).map(normalize_label)
            techs.update(vals.unique())
    else:
        for df in dfs.values():
            techs.update(df.index.astype(str))
techs = sorted(list(techs))

# Tech selection
st.sidebar.markdown("---")
st.sidebar.subheader("Technologies")
select_all_techs = st.sidebar.checkbox("Select all technologies", True)
selected_techs = techs[:] if select_all_techs else st.sidebar.multiselect("Technologies:", techs)

if not selected_techs:
    st.info("No technologies selected.")
    st.stop()

# Data matrix
bar_data = {}
for file_key, df in dfs.items():
    df_local = df.copy()
    if tech_col and tech_col in df_local.columns:
        df_local[tech_col] = df_local[tech_col].astype(str).map(normalize_label)
        s = df_local.groupby(tech_col)[selected_col].sum()
        s = s.reindex(selected_techs).fillna(0)
    else:
        s = pd.Series(df_local[selected_col].values, index=df_local.index.astype(str))
        s = s.reindex(selected_techs).fillna(0)
    bar_data[file_key] = s

plot_df = pd.DataFrame(bar_data)
plot_df = plot_df.loc[selected_techs, selected_files]
plot_df.columns = [scenario_name_map[c] for c in plot_df.columns]
scenario_labels_ordered = [scenario_name_map[f] for f in selected_files]

# Keep only nonzero techs
nonzero_mask = (plot_df.abs().sum(axis=1) > 0)
techs_to_plot = [t for t in selected_techs if nonzero_mask.get(t, False)]
if not techs_to_plot:
    st.info("All selected technologies have zero values.")
    st.stop()

# ------------------------
# Ordering
# ------------------------
pos_group_total, neg_group_total = {}, {}
tech_pos_sum, tech_neg_abs = {}, {}

for tech in techs_to_plot:
    vec = plot_df.loc[tech]
    pos = vec.clip(lower=0).sum()
    neg = vec.clip(upper=0).abs().sum()
    g = get_group(tech)

    tech_pos_sum[tech] = float(pos)
    tech_neg_abs[tech] = float(neg)
    pos_group_total[g] = pos_group_total.get(g, 0.0) + float(pos)
    neg_group_total[g] = neg_group_total.get(g, 0.0) + float(neg)

groups_pos_sorted = sorted([g for g, v in pos_group_total.items() if v > 0],
                           key=lambda g: pos_group_total[g], reverse=True)
groups_neg_sorted = sorted([g for g, v in neg_group_total.items() if v > 0],
                           key=lambda g: neg_group_total[g])

techs_ordered_pos = []
for g in groups_pos_sorted:
    ts = [t for t in techs_to_plot if get_group(t) == g and tech_pos_sum[t] > 0]
    ts = sorted(ts, key=lambda t: tech_pos_sum[t], reverse=True)
    techs_ordered_pos.extend(ts)

techs_ordered_neg = []
for g in groups_neg_sorted:
    ts = [t for t in techs_to_plot if get_group(t) == g and tech_neg_abs[t] > 0]
    ts = sorted(ts, key=lambda t: tech_neg_abs[t])
    techs_ordered_neg.extend(ts)

techs_drawn = techs_ordered_pos + [t for t in techs_ordered_neg if t not in techs_ordered_pos]

# ------------------------
# Sidebar rename & color override
# ------------------------
st.sidebar.markdown("---")
st.sidebar.subheader("Customize technologies on chart")

custom_names, custom_colors = {}, {}
for tech in techs_drawn:
    display = st.sidebar.text_input(f"Display name — {tech}", tech)
    default_col = TECH_COLORS.get(tech, stable_color_from_name(tech))
    chosen = st.sidebar.color_picker(f"Color — {tech}", default_col)
    custom_names[tech] = display
    custom_colors[tech] = chosen

# ------------------------
# Plot
# ------------------------
st.write(f"**Comparing:** {', '.join(scenario_labels_ordered)}")
fig, ax = plt.subplots(figsize=(11.5, 6.8))

bottom_pos = [0.0] * plot_df.shape[1]
bottom_neg = [0.0] * plot_df.shape[1]

# Positive bars
for tech in techs_ordered_pos:
    label = custom_names.get(tech, tech)
    fill = custom_colors.get(tech)
    values = plot_df.loc[tech].clip(lower=0).tolist()
    ax.bar(plot_df.columns, values, label=label, bottom=bottom_pos,
           color=fill, edgecolor=edge_for_fill(fill), linewidth=0.6)
    bottom_pos = [b + v for b, v in zip(bottom_pos, values)]

# Negative bars
for tech in techs_ordered_neg:
    label = custom_names.get(tech, tech)
    fill = custom_colors.get(tech)
    values = plot_df.loc[tech].clip(upper=0).tolist()
    ax.bar(plot_df.columns, values, label=label, bottom=bottom_neg,
           color=fill, edgecolor=edge_for_fill(fill), linewidth=0.6)
    bottom_neg = [b + v for b, v in zip(bottom_neg, values)]

# Y limits
ymax = max(bottom_pos) if bottom_pos else 0
ymin = min(bottom_neg) if bottom_neg else 0
if ymax == 0 and ymin == 0:
    ymax, ymin = 1, -1
ax.set_ylim(ymin * 1.05, ymax * 1.05)

# Labels and title
ax.set_ylabel(selected_col)
ax.set_xlabel("Scenario")
ax.set_title(f"{selected_col} by Technology and Scenario")
ax.ticklabel_format(axis="y", style="plain")

# FIX: Rotate x-labels so they don't overlap
plt.xticks(rotation=45, ha="right")

# Legend (deduplicated)
handles, labels = ax.get_legend_handles_labels()
seen = set()
dedup_h, dedup_l = [], []
for h, l in zip(handles, labels):
    if l not in seen:
        dedup_h.append(h); dedup_l.append(l); seen.add(l)

if dedup_l:
    ax.legend(dedup_h, dedup_l, loc="upper left",
              bbox_to_anchor=(1.02, 1.0), frameon=False)

# FIX: Increase bottom margin so labels are fully visible
plt.subplots_adjust(bottom=0.35, right=0.80)

# FIX: Let matplotlib auto-fix layout → prevents clipping
plt.tight_layout()

# Display in Streamlit
st.pyplot(fig, clear_figure=False)

# ------------------------
# Download PNG
# ------------------------
buf = io.BytesIO()
fig.savefig(buf, format="png", bbox_inches="tight", dpi=220)
buf.seek(0)
st.download_button(
    "Download chart as PNG",
    data=buf,
    file_name="scenario_comparison.png",
    mime="image/png"
)

plt.close(fig)