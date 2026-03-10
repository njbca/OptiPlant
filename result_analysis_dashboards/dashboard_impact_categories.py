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
st.set_page_config(page_title="Environmental Impact Dashboard", layout="wide")
st.title("Environmental Impact Categories by Technology")

# ------------------------
# Base paths
# ------------------------
BASE_DIR = Path(__file__).resolve().parents[1]
main_results_folder = BASE_DIR / "results" / "Full_model" / "GLS_analysis" / "Main results"

# ------------------------
# Publication-grade palette
# ------------------------
TECH_COLORS: Dict[str, str] = {
    # --- Biogas chain ---
    "Biogas1": "#6DAF62",
    "Membrane upgrading": "#2E8B2E",
    "MeOH plant - biogas": "#459E45",
    "Biogas2": "#6DAF62",
    "MeOH plant - biogasdirect": "#3C943C",
    "Biogas3": "#6DAF62",
    "CH4 plant": "#2C7F2C",

    # --- CO2 capture / MeOH from CO2 ---
    "CO2 capture DAC": "#FFE08A",
    "CO2 capture PS": "#F0C341",
    "MeOH plant - CO2": "#FFC20A",

    # --- Biomass & biochar ---
    "Biomass wood": "#6FAB67",
    "MeOH plant - biomass": "#4D9C4D",
    "Sale of biochar - biofuel": "#3A7C3A",
    "Biomass straw": "#85BB7C",
    "Biomass - Pyrolysis Unit": "#73B269",
    "Biofuel upgrading unit": "#5EA65A",
    "Sale of biochar DME": "#2D6B2D",

    # --- Biomass feedstocks ---
    "Biomass bamboo 1": "#E9D7C1",
    "Biomass bamboo 2": "#E1CCB3",
    "Biomass wheat 1": "#F1DFC8",
    "Biomass wheat 2": "#E9D4B8",

    # --- SOEC HI biomass variants ---
    "Bamboo1-stage-SOEC (HI)": "#52A252",
    "Bamboo2-stage-SOEC (HI)": "#469647",
    "Wheat1-stage-SOEC (HI)": "#5AAA5A",
    "Wheat2-stage-SOEC (HI)": "#4E9C4F",

    # --- Ammonia + ASU ---
    "NH3 plant + ASU - AEC (A)": "#009E73",
    "NH3 plant + ASU - Mix/SOEC (HI)": "#1F9F78",

    # --- Hydrogen end-use & pipelines ---
    "H2 client": "#6C93BD",
    "H2 pipeline to end-user": "#7FA3CA",

    # --- Electrolyzers ---
    "Electrolysers AEC": "#B3B3B3",
    "Electrolysers SOEC heat integrated (HI)": "#E0E0E0",
    "Electrolysers SOEC (A)": "#C8C8C8",
    "Electrolysers Mix 75AEC-25SOEC (HI)": "#D4D4D4",
    "Electrolysers Mix 75AEC-25SOEC (A)": "#BEBEBE",

    # --- Oxygen byproduct ---
    "Sale of oxygen": "#CC79A7",

    # --- Water systems ---
    "Desalination plant": "#D81B60",
    "Waste water plant": "#1FA4A9",
    "Drinking water": "#66C2B7",

    # --- Heat links ---
    "Heat from district heating": "#C9A26B",
    "Heat sent to district heating": "#B98E55",
    "Heat sent to other process": "#A6793F",

    # --- H2 storage & balance-of-plant ---
    "H2 tank compressor": "#214F78",
    "H2 tank valve": "#2A5C88",
    "H2 tank": "#316A99",
    "H2 pipes compressor": "#1A4670",
    "H2 pipes valve": "#1E527F",
    "H2 buried pipes": "#193E6A",

    # --- Solar ---
    "Solar fixed": "#F7D24B",
    "Solar tracking": "#FFC20A",

    # --- Wind ON ---
    "ON_SP198-HH100": "#4EA5D9",
    "ON_SP237-HH100": "#4EA5D9",
    "ON_SP277-HH100": "#4EA5D9",
    "ON_SP321-HH100": "#4EA5D9",
    "ON_SP198-HH150": "#A9D6F5",
    "ON_SP237-HH150": "#A9D6F5",
    "ON_SP277-HH150": "#A9D6F5",
    "ON_SP321-HH150": "#A9D6F5",

    # --- Wind OFF ---
    "OFF_SP379-HH100": "#2E73B5",
    "OFF_SP450-HH100": "#2E73B5",
    "OFF_SP379-HH150": "#7AAED6",
    "OFF_SP450-HH150": "#7AAED6",

    # --- CSP & TES ---
    "CSP Plant tower 50 MW": "#E6901D",
    "CSP Plant tower 100 MW": "#D87E00",
    "CSP Plant parabolic 50 MW": "#F0A241",
    "CSP Plant parabolic 100 MW": "#E8912B",
    "Charge TES": "#F3A86A",
    "Discharge TES": "#D9711F",
    "TES ST 50 MW": "#F09A4A",
    "TES ST 100 MW": "#E58A35",
    "TES PT 50 MW": "#F09A4A",
    "TES PT 100 MW": "#E58A35",
    "CSP+TES": "#C96E1C",

    # --- Grid, curtailment, batteries ---
    "Electricity from the grid": "#5F5F5F",
    "Curtailment": "#8C8C8C",
    "Charge batteries": "#CFCFCF",
    "Discharge batteries": "#BDBDBD",
    "Batteries": "#F2F2F2",
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
# EF normalisation factors
# Average annual impact per person
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
        "acidification": "AC",
        "climate_change": "CC",
        "ecotoxicity_freshwater": "EF",
        "energy_resources_non_renewable": "ENR",
        "eutrophication_freshwater": "EUF",
        "eutrophication_marine": "EUM",
        "eutrophication_terrestrial": "EUT",
        "human_toxicity_carcinogenic": "HTC",
        "human_toxicity_non_carcinogenic": "HTN",
        "ionising_radiation_human_health": "IR",
        "land_use": "LU",
        "material_resources_metals_minerals": "MRM",
        "ozone_depletion": "OD",
        "particulate_matter_formation": "PM",
        "photochemical_oxidant_formation_human_health": "POF",
        "water_use": "WU",
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
csv_files: List[str] = []
if main_results_folder.exists() and main_results_folder.is_dir():
    csv_files = sorted(
        [
            f for f in os.listdir(main_results_folder)
            if f.lower().startswith("scenario") and f.lower().endswith(".csv")
        ]
    )
    if csv_files:
        st.success(f"Found {len(csv_files)} scenario CSV files in the folder.")
    else:
        st.info("No files found matching 'scenario*.csv' in this folder.")
else:
    st.warning("The provided folder path does not exist or is not a directory.")
    st.stop()

if not csv_files:
    st.stop()

# ------------------------
# Sidebar controls
# ------------------------
st.sidebar.title("Scenario Options")

selected_file = st.sidebar.selectbox("Select scenario:", csv_files)

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
# Load selected scenario
# ------------------------
file_path = main_results_folder / selected_file
df = load_csv(str(file_path))

# ------------------------
# Detect technology column
# ------------------------
tech_col = None
for col_candidate in ["Type of unit", "Type of unit\n", "Technology"]:
    if col_candidate.strip() in df.columns:
        tech_col = col_candidate.strip()
        break

if tech_col is None:
    st.error("No technology column found. Expected 'Type of unit' or 'Technology'.")
    st.stop()

df[tech_col] = df[tech_col].astype(str).map(normalize_label)

# ------------------------
# Detect environmental impact columns
# ------------------------
exclude_cols = {
    tech_col, "Scenario", "scenario", "Name", "Site", "site", "ID", "id"
}

numeric_cols = [
    c for c in df.columns
    if c not in exclude_cols and pd.api.types.is_numeric_dtype(df[c])
]

if impact_basis == "Absolute":
    env_cols = [c for c in numeric_cols if " total [" in c and "/GJ" not in c]
    y_label = "Environmental impact"
else:
    env_cols = [c for c in numeric_cols if " total [" in c and "/GJ" in c]
    y_label = "Environmental impact per GJ product"

if not env_cols:
    st.error(f"No environmental impact columns found for '{impact_basis}'.")
    st.write("Available numeric columns:", numeric_cols)
    st.stop()

# ------------------------
# Technology universe
# ------------------------
techs = sorted(df[tech_col].dropna().unique().tolist())

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
# Build technology x impact-category dataframe
# ------------------------
plot_df = (
    df[df[tech_col].isin(selected_techs)]
    .groupby(tech_col)[env_cols]
    .sum()
)

# Keep all technologies except those that are zero everywhere
nonzero_mask = (plot_df.abs().sum(axis=1) > 0)
techs_to_plot = [t for t in selected_techs if nonzero_mask.get(t, False)]

if not techs_to_plot:
    st.info("All selected technologies have zero values across the chosen impact categories.")
    st.stop()

plot_df = plot_df.loc[techs_to_plot]

# Keep only impact categories with any non-zero value
nonzero_cols_mask = (plot_df.abs().sum(axis=0) > 0)
env_cols_to_plot = [c for c in env_cols if nonzero_cols_mask.get(c, False)]

if not env_cols_to_plot:
    st.info("All selected impact categories are zero for the selected technologies.")
    st.stop()

plot_df = plot_df[env_cols_to_plot]

# ------------------------
# Ordering
# ------------------------
tech_order = plot_df.abs().sum(axis=1).sort_values(ascending=False).index.tolist()
plot_df = plot_df.loc[tech_order]

impact_order = plot_df.abs().sum(axis=0).sort_values(ascending=False).index.tolist()
plot_df = plot_df[impact_order]

# ------------------------
# Optional EF normalisation
# ------------------------
if ef_normalisation == "Yes":
    plot_df = plot_df.copy()

    for col in plot_df.columns:
        key = impact_key_from_column(col)
        if key in LCA_EF_NORMALISATION_FACTORS:
            plot_df[col] = plot_df[col] / LCA_EF_NORMALISATION_FACTORS[key]

    if impact_basis == "Absolute":
        y_label = "Impact relative to one average person's yearly impact (-)"
    else:
        y_label = "Impact per GJ product relative to one average person's yearly impact (-)"

# ------------------------
# Chart mode dataframe
# ------------------------
if chart_mode == "100% stacked contribution":
    col_totals = plot_df.abs().sum(axis=0)
    plot_df_plot = plot_df.divide(col_totals.where(col_totals != 0, 1), axis=1) * 100
    y_label = "Contribution to impact category (%)"
else:
    plot_df_plot = plot_df.copy()

# ------------------------
# Customize technologies
# ------------------------
st.sidebar.markdown("---")
st.sidebar.subheader("Customize technologies on chart")

custom_names = {}
custom_colors = {}

for tech in plot_df.index:
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
# Scenario name
# ------------------------
scenario_name = choose_scenario_name(df, Path(selected_file).stem)
st.write(f"**Scenario:** {scenario_name}")
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
# Plot
# ------------------------
fig, ax = plt.subplots(figsize=(16, 7.5))

x_labels = [pretty_impact_label(c) for c in plot_df_plot.columns]
x_positions = range(len(x_labels))

bottom_pos = [0.0] * len(x_labels)
bottom_neg = [0.0] * len(x_labels)

for tech in plot_df.index:
    label = custom_names.get(tech, tech)
    fill = custom_colors.get(tech, TECH_COLORS.get(tech, stable_color_from_name(tech)))
    values = plot_df_plot.loc[tech].tolist()

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

# Y limits
ymax = max(bottom_pos) if bottom_pos else 0
ymin = min(bottom_neg) if bottom_neg else 0
if ymax == 0 and ymin == 0:
    ymax, ymin = 1, -1

if chart_mode == "100% stacked contribution":
    ax.set_ylim(0, 100)
else:
    pad_up = ymax * 0.05 if ymax != 0 else 0.05
    pad_dn = ymin * 0.05 if ymin != 0 else -0.05
    ax.set_ylim(ymin + pad_dn, ymax + pad_up)

# Labels and title
ax.set_ylabel(y_label)
ax.set_xlabel("Environmental impact category")
ax.set_title(f"Environmental impact categories by technology — {scenario_name}")

ax.set_xticks(list(x_positions))
ax.set_xticklabels(x_labels, rotation=0, ha="center", fontsize=10)
ax.ticklabel_format(axis="y", style="plain")
ax.axhline(0, color="black", linewidth=0.8)

# Legend
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

fig.tight_layout(rect=[0, 0.08, 0.82, 0.95])
st.pyplot(fig, clear_figure=False)

st.markdown("### Impact category abbreviations")

impact_reference = pd.DataFrame({
    "Abbreviation": [pretty_impact_label(c) for c in plot_df.columns],
    "Impact category": [full_impact_label(c) for c in plot_df.columns],
    "Original column": list(plot_df.columns),
})

st.dataframe(impact_reference, use_container_width=True)

# ------------------------
# Optional data table
# ------------------------
st.markdown("### Plotted data")
display_df = plot_df_plot.copy()
display_df.columns = [pretty_impact_label(c) for c in display_df.columns]
st.dataframe(display_df)

# ------------------------
# Download PNG
# ------------------------
buf = io.BytesIO()
fig.savefig(buf, format="png", bbox_inches="tight", dpi=300)
buf.seek(0)

safe_scenario_name = "".join(c if c.isalnum() or c in ("-", "_") else "_" for c in scenario_name)

st.download_button(
    "Download chart as PNG",
    data=buf,
    file_name=f"environmental_impact_{safe_scenario_name}.png",
    mime="image/png"
)

plt.close(fig)