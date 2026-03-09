# =============================================
# Hourly Series Dashboard (Aligned with Scenario Dashboard)
# Simplified: default "Batteries" color darkened
# =============================================

import os
from pathlib import Path
import io
import hashlib
import re
from typing import Dict, List

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

st.set_page_config(page_title="Hourly timeseries dashboard", layout="wide")
st.title("Hourly timeseries dashboard")

# ============================================================
# ROOT FOLDER
# ============================================================
FLOWS_RESULTS_FOLDER = (
    Path.cwd()
    / "results"
    / "Full_model"
    / "GLS_analysis"
    / "Hourly results"
    / "Flows"
)

# ============================================================
# TECH COLORS (Batteries color simplified here)
# ============================================================
TECH_COLORS: Dict[str, str] = {
    "Biogas1": "#6DAF62",
    "Membrane upgrading": "#2E8B2E",
    "MeOH plant - biogas": "#459E45",
    "Biogas2": "#6DAF62",
    "MeOH plant - biogasdirect": "#3C943C",
    "Biogas3": "#6DAF62",
    "CH4 plant": "#2C7F2C",

    "CO2 capture DAC": "#FFE08A",
    "CO2 capture PS": "#F0C341",
    "MeOH plant - CO2": "#FFC20A",

    "Biomass wood": "#6FAB67",
    "MeOH plant - biomass": "#4D9C4D",
    "Sale of biochar - biofuel": "#3A7C3A",
    "Biomass straw": "#85BB7C",
    "Biomass - Pyrolysis Unit": "#73B269",
    "Biofuel upgrading unit": "#5EA65A",
    "Sale of biochar DME": "#2D6B2D",

    "Biomass bamboo 1": "#E9D7C1",
    "Biomass bamboo 2": "#E1CCB3",
    "Biomass wheat 1": "#F1DFC8",
    "Biomass wheat 2": "#E9D4B8",

    "Bamboo1-stage-SOEC (HI)": "#52A252",
    "Bamboo2-stage-SOEC (HI)": "#469647",
    "Wheat1-stage-SOEC (HI)": "#5AAA5A",
    "Wheat2-stage-SOEC (HI)": "#4E9C4F",

    "NH3 plant + ASU - AEC (A)": "#009E73",
    "NH3 plant + ASU - Mix/SOEC (HI)": "#1F9F78",

    "H2 client": "#6C93BD",
    "H2 pipeline to end-user": "#7FA3CA",

    "Electrolysers AEC": "#B3B3B3",
    "Electrolysers SOEC heat integrated (HI)": "#E0E0E0",
    "Electrolysers SOEC (A)": "#C8C8C8",
    "Electrolysers Mix 75AEC-25SOEC (HI)": "#D4D4D4",
    "Electrolysers Mix 75AEC-25SOEC (A)": "#BEBEBE",

    "Sale of oxygen": "#CC79A7",

    "Desalination plant": "#D81B60",
    "Waste water plant": "#1FA4A9",
    "Drinking water": "#66C2B7",

    "Heat from district heating": "#C9A26B",
    "Heat sent to district heating": "#B98E55",
    "Heat sent to other process": "#A6793F",

    "H2 tank compressor": "#214F78",
    "H2 tank valve": "#2A5C88",
    "H2 tank": "#316A99",
    "H2 pipes compressor": "#1A4670",
    "H2 pipes valve": "#1E527F",
    "H2 buried pipes": "#193E6A",

    "Solar fixed": "#F7D24B",
    "Solar tracking": "#FFC20A",

    "ON_SP198-HH100": "#4EA5D9",
    "ON_SP237-HH100": "#4EA5D9",
    "ON_SP277-HH100": "#4EA5D9",
    "ON_SP321-HH100": "#4EA5D9",
    "ON_SP198-HH150": "#A9D6F5",
    "ON_SP237-HH150": "#A9D6F5",
    "ON_SP277-HH150": "#A9D6F5",
    "ON_SP321-HH150": "#A9D6F5",

    "OFF_SP379-HH100": "#2E73B5",
    "OFF_SP450-HH100": "#2E73B5",
    "OFF_SP379-HH150": "#7AAED6",
    "OFF_SP450-HH150": "#7AAED6",

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

    "Electricity from the grid": "#5F5F5F",
    "Curtailment": "#8C8C8C",
    "Charge batteries": "#CFCFCF",
    "Discharge batteries": "#BDBDBD",

    # SIMPLIFIED: Batteries now darker by default
    "Batteries": "#9E9E9E",
}

# ============================================================
# ALIASES
# ============================================================
ALIASES = {
    "meoh plant - biogas direct": "MeOH plant - biogasdirect",
    "electrolyser": "Electrolysers AEC",
    "electrolysers": "Electrolysers AEC",
    "electrolyzer aec": "Electrolysers AEC",
    "soec (a)": "Electrolysers SOEC (A)",
    "soec hi": "Electrolysers SOEC heat integrated (HI)",
    "pv fixed": "Solar fixed",
    "pv tracking": "Solar tracking",
    "grid": "Electricity from the grid",
    "grid power": "Electricity from the grid",
    "electricity grid": "Electricity from the grid",
    "battery": "Batteries",
    "battery storage": "Batteries",
    "wastewater plant": "Waste water plant",
    "dac": "CO2 capture DAC",
    "post-combustion capture": "CO2 capture PS",
}

UNIT_SUFFIX_RE = re.compile(r"\s*\[[^\]]+\]\s*$")

def normalize_label(label: str) -> str:
    s = str(label).strip()
    s = UNIT_SUFFIX_RE.sub("", s)
    s = s.replace("–", "-").replace("—", "-")
    s = re.sub(r"\s+", " ", s).strip()
    low = s.lower()
    return ALIASES.get(low, s)

def stable_color_from_name(name: str) -> str:
    h = hashlib.md5(str(name).encode("utf-8")).hexdigest()[:6]
    return f"#{int(h, 16):06x}"

# ============================================================
# LOAD CSV
# ============================================================
@st.cache_data(show_spinner=False)
def load_csv_any(path: Path) -> pd.DataFrame:
    try:
        return pd.read_csv(path)
    except:
        return pd.read_csv(path, sep=";")

# ============================================================
# DISCOVER FILES
# ============================================================
folder_path = Path(FLOWS_RESULTS_FOLDER)
if not folder_path.exists():
    st.error("Folder not found.")
    st.stop()

csv_files = [p.name for p in folder_path.glob("*.csv")]
if not csv_files:
    st.error("No CSV files found.")
    st.stop()

selected_file = st.sidebar.selectbox("Select scenario:", csv_files)
df = load_csv_any(folder_path / selected_file)

# ============================================================
# EXTRACT SCENARIO INFO
# ============================================================
info_col = next((c for c in df.columns 
                 if str(c).strip().lower() in ("information", "informations")), None)

info_pairs = []
if info_col:
    lines = df[info_col].dropna().astype(str).head(30).tolist()
    for line in lines:
        line = line.strip()
        if line:
            if ":" in line:
                k, v = line.split(":", 1)
                info_pairs.append((k.strip(), v.strip()))
            else:
                info_pairs.append(("", line))

if info_pairs:
    with st.expander("Scenario information", expanded=False):
        st.table(pd.DataFrame(info_pairs, columns=["Field", "Value"]))

# ============================================================
# TIME COLUMN DETECTION
# ============================================================
possible_time_cols = [
    c for c in df.columns if "time" in c.lower() or "hour" in c.lower()
]
time_col = possible_time_cols[0] if possible_time_cols else df.columns[0]

# ============================================================
# GROUP COLUMNS BY NORMALIZED LABEL
# ============================================================
exclude = {time_col}
if info_col:
    exclude.add(info_col)

value_cols = [c for c in df.columns if c not in exclude]

cols_by_label: Dict[str, List[str]] = {}
for c in value_cols:
    lab = normalize_label(c)
    cols_by_label.setdefault(lab, []).append(c)

all_labels = sorted(cols_by_label.keys())

# ============================================================
# SELECT SERIES
# ============================================================
st.sidebar.markdown("---")
select_all = st.sidebar.checkbox("Select all series", True)

selected_labels = all_labels[:] if select_all else st.sidebar.multiselect(
    "Series:", all_labels
)

if not selected_labels:
    st.stop()

# ============================================================
# TIME RANGE SELECTION
# ============================================================
st.sidebar.markdown("---")
st.sidebar.subheader("Time range")

n = len(df)
slider_first, slider_last = st.sidebar.select_slider(
    "Hour range", options=list(range(0, n + 1)), value=(0, n)
)

use_manual = st.sidebar.checkbox("Fill hours manually")

if use_manual:
    first_hour = st.sidebar.number_input("Start hour (index)", 0, max(n - 1, 0), slider_first)
    last_hour = st.sidebar.number_input(
        "End hour (index)", min(first_hour + 1, n), n, slider_last
    )
else:
    first_hour, last_hour = slider_first, slider_last

df_view = df.iloc[first_hour:last_hour].copy()
x_idx = list(range(first_hour, last_hour))

# ============================================================
# BUILD SERIES
# ============================================================
def build_series_for_label(lab: str) -> pd.Series:
    cols = cols_by_label.get(lab, [])
    if not cols:
        return pd.Series(dtype=float, index=df_view.index)
    s = pd.to_numeric(df_view[cols[0]], errors="coerce")
    for extra in cols[1:]:
        s = s.add(pd.to_numeric(df_view[extra], errors="coerce"), fill_value=0)
    return s

series_map = {lab: build_series_for_label(lab) for lab in selected_labels}

def is_all_zero(s: pd.Series) -> bool:
    arr = np.nan_to_num(pd.to_numeric(s, errors="coerce").values)
    return np.nanmax(np.abs(arr)) == 0

nonzero_labels = [lab for lab in selected_labels if not is_all_zero(series_map[lab])]
zero_labels = [lab for lab in selected_labels if lab not in nonzero_labels]

if not nonzero_labels:
    st.info("All selected series are zero in this window.")
    st.stop()

# ============================================================
# SIDEBAR CUSTOMIZATION
# ============================================================
st.sidebar.markdown("---")
st.sidebar.subheader("Customize series")

display_names = {}
series_colors = {}

for lab in nonzero_labels:
    display_names[lab] = st.sidebar.text_input(f"Name — {lab}", lab)
    default_c = TECH_COLORS.get(lab, stable_color_from_name(lab))
    series_colors[lab] = st.sidebar.color_picker(f"Color — {lab}", default_c)

if zero_labels:
    st.sidebar.caption("Hidden (all-zero): " + ", ".join(zero_labels))

# ============================================================
# UNIT CLASSIFICATION
# ============================================================
def detect_unit_type(original_cols: List[str]) -> str:
    unit_string = " ".join(original_cols).lower()
    if any(x in unit_string for x in ["kwh", "kwhe", "kwhth", "mwh", "mwhe"]):
        return "energy"
    if any(x in unit_string for x in ["kg", "kgh2", "kgco2", "kgmeoh", "kgo2"]):
        return "mass"
    return "other"

energy_labels, mass_labels, other_labels = [], [], []

for lab in nonzero_labels:
    cols = cols_by_label.get(lab, [])
    kind = detect_unit_type(cols)
    if kind == "energy":
        energy_labels.append(lab)
    elif kind == "mass":
        mass_labels.append(lab)
    else:
        other_labels.append(lab)

# ============================================================
# ENERGY PLOT
# ============================================================
if energy_labels:
    st.subheader("Energy flows (kWh)")
    fig1, ax1 = plt.subplots(figsize=(11, 5))
    ymax1 = 0.0

    for lab in energy_labels:
        s = series_map[lab]
        color = series_colors[lab]
        ax1.plot(x_idx, s.values, label=display_names[lab], color=color, linewidth=1.8)
        vmax = pd.to_numeric(s, errors="coerce").max()
        if pd.notna(vmax):
            ymax1 = max(ymax1, float(vmax))

    ax1.set_ylim(0, ymax1 * 1.05 if ymax1 > 0 else 1.0)
    ax1.set_xlabel("Hour (index)")
    ax1.set_ylabel("kWh")
    ax1.grid(True)
    ax1.legend(loc="center left", bbox_to_anchor=(1.0, 0.5), frameon=False)
    plt.subplots_adjust(right=0.80)
    st.pyplot(fig1)
else:
    st.info("No energy (kWh) series in this window.")

# ============================================================
# MASS PLOT
# ============================================================
if mass_labels:
    st.subheader("Mass flows (kg)")
    fig2, ax2 = plt.subplots(figsize=(11, 5))
    ymax2 = 0.0

    for lab in mass_labels:
        s = series_map[lab]
        color = series_colors[lab]
        ax2.plot(x_idx, s.values, label=display_names[lab], color=color, linewidth=1.8)
        vmax = pd.to_numeric(s, errors="coerce").max()
        if pd.notna(vmax):
            ymax2 = max(ymax2, float(vmax))

    ax2.set_ylim(0, ymax2 * 1.05 if ymax2 > 0 else 1.0)
    ax2.set_xlabel("Hour (index)")
    ax2.set_ylabel("kg")
    ax2.grid(True)
    ax2.legend(loc="center left", bbox_to_anchor=(1.0, 0.5), frameon=False)
    plt.subplots_adjust(right=0.80)
    st.pyplot(fig2)
else:
    st.info("No mass (kg) series in this window.")

# ============================================================
# PNG DOWNLOAD
# ============================================================
buf = io.BytesIO()
(fig2 if mass_labels else fig1).savefig(buf, format="png", bbox_inches="tight", dpi=200)
buf.seek(0)

st.download_button(
    "Download last chart as PNG",
    data=buf,
    file_name=f"hourly_{selected_file}_hours_{first_hour}_{last_hour-1}.png",
    mime="image/png"
)

st.info(f"Showing hours from {first_hour} to {last_hour-1}")