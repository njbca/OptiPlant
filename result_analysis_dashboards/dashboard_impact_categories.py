import os
import re
from pathlib import Path
import io
import hashlib
from typing import Dict, List, Tuple

import pandas as pd
import matplotlib.pyplot as plt
import streamlit as st
from matplotlib.colors import to_rgb

# ------------------------
# Page config (must be first Streamlit call)
# ------------------------
st.set_page_config(page_title="Environmental Impact Dashboard", layout="wide")
st.title("Environmental Impact Categories by Technology")

# ----------------------
# Folder selection
# ---------------------
st.subheader("Choose results folder under a base directory")

# Default base directory
BASE_DIR = Path.cwd() / "results" / "Full_model" / "GLS_analysis"

# Optional: allow changing the base dir from the UI
with st.expander("Change base directory"):
    base_input = st.text_input("Base directory path", value=str(BASE_DIR))
    if base_input:
        BASE_DIR = Path(base_input).expanduser().resolve()

# Helper to list subdirectories up to depth
def list_subdirs(root: Path, depth: int = 3) -> List[Path]:
    out: List[Path] = []
    if not root.exists():
        return out
    out.append(root)
    if depth <= 0:
        return out
    for p in root.iterdir():
        if p.is_dir():
            out.extend(list_subdirs(p, depth - 1))
    return out

if not BASE_DIR.exists():
    st.error(f"Base directory does not exist: {BASE_DIR}")
    main_results_folder = None
else:
    subdirs = [p for p in list_subdirs(BASE_DIR, depth=3) if p.is_dir()]
    if not subdirs:
        st.warning(f"No subfolders found under: {BASE_DIR}")
        main_results_folder = None
    else:
        key_last = "results_dir_last_choice"
        last_choice = Path(st.session_state[key_last]) if key_last in st.session_state else None

        def is_under_base(p: Path, base: Path) -> bool:
            try:
                p.resolve().relative_to(base.resolve())
                return True
            except Exception:
                return False

        if last_choice and last_choice.exists() and is_under_base(last_choice, BASE_DIR):
            default_index = subdirs.index(last_choice) if last_choice in subdirs else 0
        else:
            # pick the "deepest" subdirectory under BASE_DIR
            default_index = max(range(len(subdirs)), key=lambda i: len(subdirs[i].parts))

        choice = st.selectbox(
            "Select a folder:",
            options=subdirs,
            index=default_index,
            format_func=lambda p: str(p.relative_to(BASE_DIR)) if p != BASE_DIR else ".",
        )

        if choice and choice.is_dir():
            main_results_folder = choice
            st.session_state[key_last] = str(choice)
        else:
            st.warning("Please select a valid folder.")
            main_results_folder = None

# ------------------------
# Publication-grade palette
# ------------------------
TECH_COLORS: Dict[str, str] = {
    # --- Biogas chain (greens; olive–forest range) ---
    "Biogas1": "#6DAF62",
    "Membrane upgrading": "#197219",
    "MeOH plant - biogas": "#0B4D0B",
    "Biogas2": "#6DAF62",
    "MeOH plant - biogasdirect": "#3C943C",
    "Biogas3": "#6DAF62",
    "CH4 plant": "#2C7F2C",
    # --- CO2 capture / MeOH from CO2 (yellows) ---
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
    # --- Ammonia + ASU (bluish‑green) ---
    "NH3 plant + ASU - AEC (A)": "#009E73",
    "NH3 plant + ASU - Mix/SOEC (HI)": "#1F9F78",
    # --- Hydrogen end‑use & pipelines (blue‑grey) ---
    "H2 client": "#6C93BD",
    "H2 pipeline to end-user": "#7FA3CA",
    # --- Electrolyzers (greys) ---
    "Electrolysers AEC": "#B3B3B3",
    "Electrolysers SOEC heat integrated (HI)": "#E0E0E0",
    "Electrolysers SOEC (A)": "#C8C8C8",
    "Electrolysers Mix 75AEC-25SOEC (HI)": "#D4D4D4",
    "Electrolysers Mix 75AEC-25SOEC (A)":  "#BEBEBE",
    # --- Oxygen byproduct (magenta) ---
    "Sale of oxygen": "#CC79A7",
    # --- Water systems (TEAL family; desal kept as accent) ---
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
    # --- Solar (bright yellows) ---
    "Solar fixed":   "#F7D24B",
    "Solar tracking":"#FFC20A",
    # --- Wind ON (sky blues) ---
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
    # --- CSP & TES (orange family) ---
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
    # --- Grid, curtailment, batteries (greys by lightness) ---
    "Electricity from the grid": "#5F5F5F",
    "Curtailment":               "#8C8C8C",
    "Charge batteries":    "#CFCFCF",
    "Discharge batteries": "#BDBDBD",
    # Batteries default (align with Hourly Dashboard)
    "Batteries":           "#E323C6",
}

# ------------------------
# Aliases
# ------------------------
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
    # CO2 capture
    "DAC": "CO2 capture DAC",
    "Post-combustion capture": "CO2 capture PS",
}

# ------------------------
# EF normalisation factors (average annual impact per person)
# ------------------------
LCA_EF_NORMALISATION_FACTORS = {
    "acidification": 55.6,
    "climate_change": 7550.0,
    "ecotoxicity_freshwater": 56700.0,
    "energy_resources_non_renewable": 65000.0,
    "eutrophication_freshwater": 1.61,
    "eutrophication_marine": 19.5,
    "eutrophication_terrestrial": 177.0,
    "human_toxicity_carcinogenic": 0.0000173,
    "human_toxicity_non_carcinogenic": 0.000129,
    "ionising_radiation_human_health": 4220.0,
    "land_use": 819000.0,
    "material_resources_metals_minerals": 0.0636,
    "ozone_depletion": 0.0523,
    "particulate_matter_formation": 0.000595,
    "photochemical_oxidant_formation_human_health": 40.9,
    "water_use": 11500.0,
}

def normalize_label(label: str) -> str:
    return ALIASES.get(str(label).strip(), str(label).strip())

# ------------------------
# Utility helpers
# ------------------------
def stable_color_from_name(name: str) -> str:
    h = hashlib.md5(str(name).encode("utf-8")).hexdigest()[:6]
    return f"#{int(h, 16):06x}"

def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def relative_luminance_hex(hex_color: str) -> float:
    r, g, b = to_rgb(hex_color)
    R = _srgb_to_linear(r)
    G = _srgb_to_linear(g)
    B = _srgb_to_linear(b)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B

def edge_for_fill(hex_color: str) -> str:
    L = relative_luminance_hex(hex_color)
    return "#222222" if L > 0.72 else "#FFFFFF"

@st.cache_data(show_spinner=False)
def load_csv(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]
    return df

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

def pretty_impact_label(col: str) -> str:
    base = str(col).split(" total [")[0]
    mapping = {
        "acidification": "Acidification",
        "climate_change": "Climate change",
        "ecotoxicity_freshwater": "Freshwater ecotoxicity",
        "energy_resources_non_renewable": "Non-ren. energy resources",
        "eutrophication_freshwater": "Freshwater eutrophication",
        "eutrophication_marine": "Marine eutrophication",
        "eutrophication_terrestrial": "Terrestrial eutrophication",
        "human_toxicity_carcinogenic": "Human toxicity (carcinogenic)",
        "human_toxicity_non_carcinogenic": "Human toxicity (non-carcinogenic)",
        "ionising_radiation_human_health": "Ionising radiation",
        "land_use": "Land use",
        "material_resources_metals_minerals": "Material resources (metals & minerals)",
        "ozone_depletion": "Ozone depletion",
        "particulate_matter_formation": "Particulate matter formation",
        "photochemical_oxidant_formation_human_health": "Photochemical oxidant formation",
        "water_use": "Water use",
    }
    return mapping.get(base, base[:4].upper())

def full_impact_label(col: str) -> str:
    base = str(col).split(" total [")[0]
    mapping = {
        "acidification": "Acidification",
        "climate_change": "Climate change",
        "ecotoxicity_freshwater": "Freshwater ecotoxicity",
        "energy_resources_non_renewable": "Non-renewable energy resources",
        "eutrophication_freshwater": "Freshwater eutrophication",
        "eutrophication_marine": "Marine eutrophication",
        "eutrophication_terrestrial": "Terrestrial eutrophication",
        "human_toxicity_carcinogenic": "Human toxicity (carcinogenic)",
        "human_toxicity_non_carcinogenic": "Human toxicity (non-carcinogenic)",
        "ionising_radiation_human_health": "Ionising radiation",
        "land_use": "Land use",
        "material_resources_metals_minerals": "Material resources (metals & minerals)",
        "ozone_depletion": "Ozone depletion",
        "particulate_matter_formation": "Particulate matter formation",
        "photochemical_oxidant_formation_human_health": "Photochemical oxidant formation",
        "water_use": "Water use",
    }
    return mapping.get(base, base.replace("_", " ").title())

def impact_key_from_column(col: str) -> str:
    return str(col).split(" total [")[0].strip()

# ------------------------
# File discovery
# ------------------------
def natural_sort_key(name: str):
    return [int(t) if t.isdigit() else t.lower() for t in re.findall(r"\d+|\D+", name)]

csv_files: List[str] = []
if main_results_folder and Path(main_results_folder).exists() and Path(main_results_folder).is_dir():
    folder_path = Path(main_results_folder)
    csv_files = sorted([f.name for f in folder_path.glob("*.csv")], key=natural_sort_key)
    if csv_files:
        st.success(f"Found {len(csv_files)} CSV files in the folder.")
    else:
        st.info("No CSV files found in this folder.")
else:
    st.warning("The provided folder path does not exist or is not a directory.")
    st.stop()

if not csv_files:
    st.stop()

# ------------------------
# Sidebar controls (comparison)
# ------------------------
st.sidebar.title("Scenario Options")

selected_files = st.sidebar.multiselect(
    "Select up to two scenarios:",
    csv_files,
    default=[],
)

if not selected_files:
    st.info("Select at least one scenario file to proceed.")
    st.stop()

if len(selected_files) > 2:
    st.sidebar.warning("You selected more than two scenarios — only the first two will be used.")
    selected_files = selected_files[:2]

impact_basis = st.sidebar.radio(
    "Impact basis:",
    ["Absolute", "Per GJ product"],
    index=1
)

chart_mode = st.sidebar.radio(
    "Chart mode:",
    ["Absolute values", "100% stacked contribution"],
    index=0
)

ef_normalisation = st.sidebar.radio(
    "EF normalisation:",
    ["No", "Yes"],
    index=0
)

# ------------------------
# Load selected scenario(s)
# ------------------------
dfs = []
scenario_names = []
for f in selected_files:
    path = Path(main_results_folder) / f
    df_raw = load_csv(str(path))

    # Detect technology column
    tech_col = None
    for col_candidate in ["Type of unit", "Type of unit\n", "Technology"]:
        if col_candidate.strip() in df_raw.columns:
            tech_col = col_candidate.strip()
            break
    if tech_col is None:
        st.error(f"No technology column found in '{f}'. Expected 'Type of unit' or 'Technology'.")
        st.stop()

    df_raw[tech_col] = df_raw[tech_col].astype(str).map(normalize_label)

    # Save processed df and name
    dfs.append((f, df_raw, tech_col))
    scenario_names.append(choose_scenario_name(df_raw, Path(f).stem))

# Use a single tech_col key name (assume consistent naming per file)
main_tech_col = dfs[0][2]
aligned = []
for fname, df_raw, tech_col in dfs:
    if tech_col != main_tech_col:
        df_raw = df_raw.rename(columns={tech_col: main_tech_col})
    aligned.append((fname, df_raw))

# ------------------------
# Determine numeric columns and impact columns (union across scenarios)
# ------------------------
exclude_cols = {main_tech_col, "Scenario", "scenario", "Name", "Site", "site", "ID", "id"}

def numeric_env_cols(df: pd.DataFrame, basis: str) -> List[str]:
    numeric_cols = [c for c in df.columns if c not in exclude_cols and pd.api.types.is_numeric_dtype(df[c])]
    if basis == "Absolute":
        env = [c for c in numeric_cols if " total [" in c and "/GJ" not in c]
    else:
        env = [c for c in numeric_cols if " total [" in c and "/GJ" in c]
    return env

env_cols_union: List[str] = []
for _, df_raw in aligned:
    env_cols_union = sorted(set(env_cols_union) | set(numeric_env_cols(df_raw, impact_basis)))

if not env_cols_union:
    st.error(f"No environmental impact columns found for '{impact_basis}'.")
    st.stop()

# ------------------------
# Technology universe (union across scenarios)
# ------------------------
all_techs = set()
for _, df_raw in aligned:
    all_techs |= set(df_raw[main_tech_col].dropna().astype(str).unique().tolist())
techs = sorted(all_techs)

st.sidebar.markdown("---")
st.sidebar.subheader("Technologies")

select_all_techs = st.sidebar.checkbox("Select all technologies", value=True)

if select_all_techs:
    selected_techs = techs[:]
else:
    selected_techs = st.sidebar.multiselect(
        "Technologies to include:",
        options=techs,
        default=[]
    )

if not selected_techs:
    st.info("No technologies selected. Choose at least one to draw the chart.")
    st.stop()

# ------------------------
# Build per-scenario plot tables on the unified category set
# (FIX 1: ensure unique tech index via groupby(level=0).sum())
# ------------------------
def build_plot_df(df_raw: pd.DataFrame, env_cols: List[str], tech_col: str, selected_techs: List[str]) -> pd.DataFrame:
    df2 = df_raw.copy()
    # Ensure all env columns exist; if missing, add zeros
    for c in env_cols:
        if c not in df2.columns:
            df2[c] = 0.0
    # Keep selected techs
    df2 = df2[df2[tech_col].isin(selected_techs)]
    # Group and sum; ensure unique index
    plot_df = df2.groupby(tech_col)[env_cols].sum()
    plot_df = plot_df.groupby(level=0).sum()
    # Drop techs that are all-zero
    nonzero_mask = (plot_df.abs().sum(axis=1) > 0)
    plot_df = plot_df.loc[nonzero_mask]
    return plot_df

per_scenario_plotdfs = []
for _, df_raw in aligned:
    plot_df = build_plot_df(df_raw, env_cols_union, main_tech_col, selected_techs)
    per_scenario_plotdfs.append(plot_df)

# Determine impact categories to plot (non-zero in at least one scenario)
if per_scenario_plotdfs:
    col_nonzero_union = pd.concat([df.abs().sum(axis=0) for df in per_scenario_plotdfs], axis=1).sum(axis=1)
else:
    col_nonzero_union = pd.Series(dtype=float)

env_cols_to_plot = [c for c in env_cols_union if col_nonzero_union.get(c, 0) > 0]

if not env_cols_to_plot:
    st.info("All selected impact categories are zero across the selected technologies/scenarios.")
    st.stop()

# Determine ordering: technologies by union magnitude and impact categories by union magnitude
# Tech order (FIX 1: collapse duplicates when computing union totals)
if per_scenario_plotdfs:
    tech_totals_union = (
        pd.concat(per_scenario_plotdfs, axis=0)
          .groupby(level=0).sum()
          .abs().sum(axis=1)
          .sort_values(ascending=False)
    )
    tech_order = tech_totals_union.index.tolist()
else:
    tech_order = []

# Impact order by union magnitude
impact_totals_union = (
    pd.concat(per_scenario_plotdfs, axis=0)
      .groupby(level=0).sum()  # ensures consistent shape if needed
      .abs().sum(axis=0)
)
impact_order = impact_totals_union[env_cols_to_plot].sort_values(ascending=False).index.tolist()

# Reindex each scenario's plot df to common order (missing techs allowed)
ordered_plotdfs = []
for plot_df in per_scenario_plotdfs:
    plot_df = plot_df.groupby(level=0).sum()  # ensure unique index (defensive)
    order_this = [t for t in tech_order if t in plot_df.index]
    df_re = plot_df.reindex(index=order_this, columns=impact_order, fill_value=0.0)
    ordered_plotdfs.append(df_re)

# ------------------------
# Optional EF normalisation
# ------------------------
def apply_ef_normalisation(plot_df: pd.DataFrame) -> pd.DataFrame:
    out = plot_df.copy()
    for col in out.columns:
        key = impact_key_from_column(col)
        if key in LCA_EF_NORMALISATION_FACTORS:
            out[col] = out[col] / LCA_EF_NORMALISATION_FACTORS[key]
    return out

if ef_normalisation == "Yes":
    ordered_plotdfs = [apply_ef_normalisation(df) for df in ordered_plotdfs]
    if impact_basis == "Absolute":
        y_label = "Impact relative to one average person's yearly impact (-)"
    else:
        y_label = "Impact per GJ product relative to one average person's yearly impact (-)"
else:
    y_label = "Environmental impact" if impact_basis == "Absolute" else "Environmental impact per GJ product"

# ------------------------
# Chart mode dataframe
# ------------------------
def to_chart_mode(plot_df: pd.DataFrame) -> pd.DataFrame:
    if chart_mode == "100% stacked contribution":
        col_totals = plot_df.abs().sum(axis=0).replace(0, 1.0)
        return plot_df.divide(col_totals, axis=1) * 100.0
    return plot_df

plotdfs_for_plot = [to_chart_mode(df) for df in ordered_plotdfs]

# ------------------------
# Customize technologies (use union of techs present in at least one scenario)
# ------------------------
all_techs_present = sorted(set().union(*[df.index.tolist() for df in ordered_plotdfs]))
st.sidebar.markdown("---")
st.sidebar.subheader("Customize technologies on chart")

custom_names: Dict[str, str] = {}
custom_colors: Dict[str, str] = {}

for tech in all_techs_present:
    display_name = st.sidebar.text_input(
        f"Display name — {tech}",
        value=tech,
        key=f"display_name_{tech}"
    )
    color_default = TECH_COLORS.get(tech, stable_color_from_name(tech))
    color = st.sidebar.color_picker(
        f"Color — {tech}",
        value=color_default,
        key=f"color_{tech}"
    )
    custom_names[tech] = display_name
    custom_colors[tech] = color

# ------------------------
# Scenario labels
# ------------------------
for i, name in enumerate(scenario_names):
    st.write(f"**Scenario {i+1}:** {name}")
st.write(f"**Impact basis:** {impact_basis}")
st.write(f"**Chart mode:** {chart_mode}")
st.write(f"**EF normalisation:** {ef_normalisation}")

if ef_normalisation == "Yes":
    st.info(
        "Values are divided by the average annual environmental impact of one person "
        "for each impact category. A value of 1 means the impact is equal to one "
        "average person's yearly impact in that category."
    )

# ------------------------
# Compute shared y-limits (for consistent axis size)
# ------------------------
def stacked_extremes(plot_df_plot: pd.DataFrame) -> Tuple[float, float]:
    # plot_df_plot: rows=techs, cols=impact categories
    pos_sums = plot_df_plot.clip(lower=0).sum(axis=0)
    neg_sums = plot_df_plot.clip(upper=0).sum(axis=0)
    ymax = float(pos_sums.max()) if not pos_sums.empty else 0.0
    ymin = float(neg_sums.min()) if not neg_sums.empty else 0.0
    return ymin, ymax

if chart_mode == "100% stacked contribution":
    global_ymin, global_ymax = 0.0, 100.0
else:
    ymins, ymaxs = [], []
    for dfp in plotdfs_for_plot:
        ymin, ymax = stacked_extremes(dfp)
        ymins.append(ymin)
        ymaxs.append(ymax)
    global_ymin = min(ymins) if ymins else 0.0
    global_ymax = max(ymaxs) if ymaxs else 0.0
    # Add padding similar to original approach
    pad_up = global_ymax * 0.05 if global_ymax != 0 else 0.05
    pad_dn = global_ymin * 0.05 if global_ymin != 0 else -0.05
    global_ymin = global_ymin + pad_dn
    global_ymax = global_ymax + pad_up
    if global_ymax == global_ymin:
        global_ymax, global_ymin = 1.0, -1.0

# ------------------------
# Plot helper (FIX 2: collapse duplicate techs defensively)
# ------------------------
def draw_stacked_chart(plot_df_plot: pd.DataFrame, scenario_name: str):
    # Defensive: ensure unique tech index
    if not plot_df_plot.index.is_unique:
        plot_df_plot = plot_df_plot.groupby(level=0).sum()

    fig, ax = plt.subplots(figsize=(16, 8.0))
    x_labels = [pretty_impact_label(c) for c in plot_df_plot.columns]
    x_positions = range(len(x_labels))

    bottom_pos = [0.0] * len(x_labels)
    bottom_neg = [0.0] * len(x_labels)

    for tech in plot_df_plot.index:
        label = custom_names.get(tech, tech)
        fill = custom_colors.get(tech, TECH_COLORS.get(tech, stable_color_from_name(tech)))

        row = plot_df_plot.loc[tech]
        # If row is a DataFrame (duplicate labels), collapse to one Series
        if isinstance(row, pd.DataFrame):
            row = row.sum(axis=0)

        values = row.to_list()

        pos_values = [v if v > 0 else 0 for v in values]
        neg_values = [v if v < 0 else 0 for v in values]

        if any(v != 0 for v in pos_values):
            ax.bar(
                x_positions,
                pos_values,
                label=label,
                bottom=bottom_pos,
                color=fill,
                edgecolor=edge_for_fill(fill),
                linewidth=0.6
            )
            bottom_pos = [b + v for b, v in zip(bottom_pos, pos_values)]

        if any(v != 0 for v in neg_values):
            ax.bar(
                x_positions,
                neg_values,
                label=label,
                bottom=bottom_neg,
                color=fill,
                edgecolor=edge_for_fill(fill),
                linewidth=0.6
            )
            bottom_neg = [b + v for b, v in zip(bottom_neg, neg_values)]

    # Shared y-limits
    ax.set_ylim(global_ymin, global_ymax)

    # Labels and title
    ax.set_ylabel(y_label)
    ax.set_xlabel("Environmental impact category")
    ax.set_title(f"Environmental impact categories by technology — {scenario_name}")

    ax.set_xticks(list(x_positions))
    ax.set_xticklabels(x_labels, rotation=45, ha="right", fontsize=9)

    ax.ticklabel_format(axis="y", style="plain")
    ax.axhline(0, color="black", linewidth=0.8)

    # Legend (deduplicate)
    handles, labels = ax.get_legend_handles_labels()
    seen, dedup_h, dedup_l = set(), [], []
    for h, l in zip(handles, labels):
        if l not in seen:
            dedup_h.append(h)
            dedup_l.append(l)
            seen.add(l)
    if dedup_l:
        ax.legend(
            dedup_h,
            dedup_l,
            loc="upper left",
            bbox_to_anchor=(1.02, 1.0),
            borderaxespad=0.0,
            frameon=False
        )

    fig.tight_layout(rect=[0, 0.12, 0.82, 0.95])
    return fig

# ------------------------
# Render one or two charts + downloads
# ------------------------
impact_reference = pd.DataFrame({
    "Abbreviation": [pretty_impact_label(c) for c in impact_order],
    "Impact category": [full_impact_label(c) for c in impact_order],
    "Original column": list(impact_order),
})

for idx, df_plot in enumerate(plotdfs_for_plot):
    # If no techs remain for this scenario, skip
    if df_plot.empty:
        st.info(f"No non-zero data for the selected technologies in Scenario {idx+1} ({scenario_names[idx]}).")
        continue

    scenario_name = scenario_names[idx]
    fig = draw_stacked_chart(df_plot, scenario_name)
    st.pyplot(fig, clear_figure=False)

    # Data table for this scenario
    st.markdown(f"### Plotted data — {scenario_name}")
    display_df = df_plot.copy()
    display_df.columns = [pretty_impact_label(c) for c in display_df.columns]
    st.dataframe(display_df, use_container_width=True)

    # Download PNG for this figure
    buf = io.BytesIO()
    fig.savefig(buf, format="png", bbox_inches="tight", dpi=300)
    buf.seek(0)
    safe_name = "".join(c if c.isalnum() or c in ("-", "_") else "_" for c in scenario_name)
    st.download_button(
        f"Download chart as PNG — {scenario_name}",
        data=buf,
        file_name=f"environmental_impact_{safe_name}.png",
        mime="image/png",
        key=f"download_{idx}_{safe_name}"
    )
    plt.close(fig)

# ------------------------
# Impact category abbreviations (shared)
# ------------------------
st.markdown("### Impact category abbreviations (shared across charts)")
st.dataframe(impact_reference, use_container_width=True)