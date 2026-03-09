# =============================================
# Hourly Series Dashboard — Sequential charts, per-figure legends
# - Folder selection in MAIN (depth fixed to 4)
# - CSV selection in SIDEBAR (1 or 2 scenarios)
# - Larger plots; legend on each figure
# - If two scenarios: show Scenario A figure then Scenario B (sequential),
#   with shared y-limits per metric for fair visual comparison
# - PNG downloads for each chart
# =============================================

from pathlib import Path
import io
import hashlib
import re
from typing import Dict, List

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


# -------------------------------------------------
# Page config (must be first)
# -------------------------------------------------
st.set_page_config(page_title="Hourly timeseries dashboard", layout="wide")
st.title("Hourly timeseries dashboard")

# -------------------------------------------------
# Seed the SIDEBAR so it appears from the start
# -------------------------------------------------
st.sidebar.title("Hourly options")
st.sidebar.caption("Pick folder & CSVs in the main area → configure series & time here.")


# ============================================================
# BASE DIR + FOLDER SELECTION (IN MAIN; depth fixed to 4)
# ============================================================
DEFAULT_BASE_DIR = Path.cwd() / "results" / "Full_model" / "GLS_analysis"

st.subheader("Choose results folder under a base directory")
with st.expander("Change base directory"):
    base_input = st.text_input("Base directory path", value=str(DEFAULT_BASE_DIR))
BASE_DIR = Path(base_input).expanduser().resolve() if base_input else DEFAULT_BASE_DIR

def list_subdirs(root: Path, depth: int = 4) -> list[Path]:
    """Return a flat list of subdirectories including root up to a given depth (fixed to 4)."""
    out = []
    if not root.exists():
        return out
    out.append(root)
    if depth <= 0:
        return out
    for p in root.iterdir():
        if p.is_dir():
            out.extend(list_subdirs(p, depth - 1))
    return out

def is_under_base(p: Path, base: Path) -> bool:
    try:
        p.resolve().relative_to(base.resolve())
        return True
    except Exception:
        return False

def natural_sort_key(name: str):
    # Sort "Scenario 2.csv" before "Scenario 10.csv"
    return [int(t) if t.isdigit() else t.lower() for t in re.findall(r"\d+|\D+", name)]

# Discover subfolders (depth fixed to 4) — all in MAIN
if not BASE_DIR.exists():
    st.error(f"Base directory does not exist: {BASE_DIR}")
    st.stop()

subdirs = [p for p in list_subdirs(BASE_DIR, depth=4) if p.is_dir()]
if not subdirs:
    st.warning(f"No subfolders found under: {BASE_DIR}")
    st.stop()

# Remember last chosen folder; default to deepest
key_last = "hourly_results_dir_last_choice"
last_choice = Path(st.session_state[key_last]) if key_last in st.session_state else None
if last_choice and last_choice.exists() and is_under_base(last_choice, BASE_DIR):
    default_index = subdirs.index(last_choice) if last_choice in subdirs else 0
else:
    default_index = max(range(len(subdirs)), key=lambda i: len(subdirs[i].parts))

folder_path = st.selectbox(
    "Select a folder:",
    options=subdirs,
    index=default_index,
    format_func=lambda p: str(p.relative_to(BASE_DIR)) if p != BASE_DIR else ".",
)
st.session_state[key_last] = str(folder_path)

# Discover CSVs (MAIN)
csv_files = sorted([p.name for p in folder_path.glob("*.csv")], key=natural_sort_key)
if not csv_files:
    st.info("No CSV files found in this folder.")
    st.stop()


# ============================================================
# CSV SELECTION (IN SIDEBAR → 1 or 2 scenarios)
# ============================================================
st.sidebar.markdown("---")
selected_files = st.sidebar.multiselect(
    "Select one or two scenario CSVs:",
    options=csv_files,
    default=csv_files[:2] if len(csv_files) >= 2 else csv_files
)

if len(selected_files) == 0:
    st.info("Please select at least one scenario CSV in the sidebar.")
    st.stop()
elif len(selected_files) > 2:
    st.warning("You selected more than two. Using the first two.")
    selected_files = selected_files[:2]

# Paths & stems
paths = [folder_path / f for f in selected_files]
stems = [Path(f).stem for f in selected_files]


# ============================================================
# COLORS & ALIASES
# ============================================================
TECH_COLORS: Dict[str, str] = {
    "Biogas1": "#6DAF62", "Membrane upgrading": "#197219", "MeOH plant - biogas": "#032803",
    "Biogas2": "#6DAF62", "MeOH plant - biogasdirect": "#3C943C", "Biogas3": "#6DAF62",
    "CH4 plant": "#2C7F2C",

    "CO2 capture DAC": "#FFE08A", "CO2 capture PS": "#F0C341", "MeOH plant - CO2": "#FFC20A",

    "Biomass wood": "#6FAB67", "MeOH plant - biomass": "#4D9C4D",
    "Sale of biochar - biofuel": "#3A7C3A", "Biomass straw": "#85BB7C",
    "Biomass - Pyrolysis Unit": "#73B269", "Biofuel upgrading unit": "#5EA65A",
    "Sale of biochar DME": "#2D6B2D",

    "Biomass bamboo 1": "#E9D7C1", "Biomass bamboo 2": "#E1CCB3",
    "Biomass wheat 1": "#F1DFC8", "Biomass wheat 2": "#E9D4B8",

    "Bamboo1-stage-SOEC (HI)": "#52A252", "Bamboo2-stage-SOEC (HI)": "#469647",
    "Wheat1-stage-SOEC (HI)": "#5AAA5A", "Wheat2-stage-SOEC (HI)": "#4E9C4F",

    "NH3 plant + ASU - AEC (A)": "#009E73", "NH3 plant + ASU - Mix/SOEC (HI)": "#1F9F78",

    "H2 client": "#6C93BD", "H2 pipeline to end-user": "#7FA3CA",

    "Electrolysers AEC": "#B3B3B3", "Electrolysers SOEC heat integrated (HI)": "#E0E0E0",
    "Electrolysers SOEC (A)": "#C8C8C8",
    "Electrolysers Mix 75AEC-25SOEC (HI)": "#D4D4D4",
    "Electrolysers Mix 75AEC-25SOEC (A)": "#BEBEBE",

    "Sale of oxygen": "#CC79A7",

    "Desalination plant": "#D81B60", "Waste water plant": "#1FA4A9",
    "Drinking water": "#66C2B7",

    "Heat from district heating": "#C9A26B",
    "Heat sent to district heating": "#B98E55",
    "Heat sent to other process": "#A6793F",

    "H2 tank compressor": "#214F78", "H2 tank valve": "#2A5C88", "H2 tank": "#316A99",
    "H2 pipes compressor": "#1A4670", "H2 pipes valve": "#1E527F", "H2 buried pipes": "#193E6A",

    "Solar fixed": "#F7D24B", "Solar tracking": "#FFC20A",

    "ON_SP198-HH100": "#4EA5D9", "ON_SP237-HH100": "#4EA5D9",
    "ON_SP277-HH100": "#4EA5D9", "ON_SP321-HH100": "#4EA5D9",
    "ON_SP198-HH150": "#A9D6F5", "ON_SP237-HH150": "#A9D6F5",
    "ON_SP277-HH150": "#A9D6F5", "ON_SP321-HH150": "#A9D6F5",

    "OFF_SP379-HH100": "#2E73B5", "OFF_SP450-HH100": "#2E73B5",
    "OFF_SP379-HH150": "#7AAED6", "OFF_SP450-HH150": "#7AAED6",

    "CSP Plant tower 50 MW": "#E6901D", "CSP Plant tower 100 MW": "#D87E00",
    "CSP Plant parabolic 50 MW": "#F0A241", "CSP Plant parabolic 100 MW": "#E8912B",
    "Charge TES": "#F3A86A", "Discharge TES": "#D9711F",
    "TES ST 50 MW": "#F09A4A", "TES ST 100 MW": "#E58A35",
    "TES PT 50 MW": "#F09A4A", "TES PT 100 MW": "#E58A35",
    "CSP+TES": "#C96E1C",

    "Electricity from the grid": "#5F5F5F", "Curtailment": "#8C8C8C",
    "Charge batteries": "#CFCFCF", "Discharge batteries": "#BDBDBD",

    # Batteries darker by default
    "Batteries": "#E323C6",
}

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
# LOAD CSV(s)
# ============================================================
@st.cache_data(show_spinner=False)
def load_csv_any(path: Path) -> pd.DataFrame:
    try:
        return pd.read_csv(path)
    except Exception:
        return pd.read_csv(path, sep=";")

dfs = [load_csv_any(p) for p in paths]


# ============================================================
# Scenario information (optional)
# ============================================================
def scenario_info_pairs(df: pd.DataFrame):
    info_col = next((c for c in df.columns
                     if str(c).strip().lower() in ("information", "informations")), None)
    pairs = []
    if info_col:
        lines = df[info_col].dropna().astype(str).head(30).tolist()
        for line in lines:
            line = line.strip()
            if line:
                if ":" in line:
                    k, v = line.split(":", 1)
                    pairs.append((k.strip(), v.strip()))
                else:
                    pairs.append(("", line))
    return pairs

infos = [scenario_info_pairs(df) for df in dfs]
if any(infos):
    with st.expander("Scenario information"):
        if len(dfs) == 1:
            st.markdown(f"**{stems[0]}**")
            st.table(pd.DataFrame(infos[0], columns=["Field", "Value"]))
        else:
            st.markdown(f"**{stems[0]}**")
            st.table(pd.DataFrame(infos[0], columns=["Field", "Value"]))
            st.markdown(f"**{stems[1]}**")
            st.table(pd.DataFrame(infos[1], columns=["Field", "Value"]))


# ============================================================
# TIME COLUMN DETECTION
# ============================================================
def detect_time_col(df: pd.DataFrame) -> str:
    preferred = ["Time", "Hour", "Hours", "Datetime", "Timestamp"]
    exact = [c for c in df.columns if c in preferred]
    if exact:
        return exact[0]
    fuzzy = [c for c in df.columns if ("time" in c.lower() or "hour" in c.lower())]
    return fuzzy[0] if fuzzy else df.columns[0]

time_cols = [detect_time_col(df) for df in dfs]


# ============================================================
# BUILD LABEL MAPS & SERIES HELPERS
# ============================================================
def labels_map(df: pd.DataFrame, time_col: str):
    exclude = {time_col}
    info_col = next((c for c in df.columns
                     if str(c).strip().lower() in ("information", "informations")), None)
    if info_col:
        exclude.add(info_col)
    value_cols = [c for c in df.columns if c not in exclude]
    cols_by_label: Dict[str, List[str]] = {}
    for c in value_cols:
        lab = normalize_label(c)
        cols_by_label.setdefault(lab, []).append(c)
    return cols_by_label

cols_by_label_list = [labels_map(df, t) for df, t in zip(dfs, time_cols)]

def build_series(df_view: pd.DataFrame, cols_by_label: Dict[str, List[str]], lab: str) -> pd.Series:
    cols = cols_by_label.get(lab, [])
    if not cols:
        return pd.Series(0.0, index=df_view.index, dtype=float)
    s = pd.to_numeric(df_view[cols[0]], errors="coerce")
    for extra in cols[1:]:
        s = s.add(pd.to_numeric(df_view[extra], errors="coerce"), fill_value=0)
    return s

def is_all_zero(s: pd.Series) -> bool:
    arr = np.nan_to_num(pd.to_numeric(s, errors="coerce").values)
    return np.nanmax(np.abs(arr)) == 0

def detect_unit_type(original_cols: List[str]) -> str:
    unit_string = " ".join(original_cols or []).lower()
    if any(x in unit_string for x in ["kwh", "kwhe", "kwhth", "mwh", "mwhe"]):
        return "energy"
    if any(x in unit_string for x in ["kg", "kgh2", "kgco2", "kgmeoh", "kgo2"]):
        return "mass"
    return "other"


# ============================================================
# SIDEBAR: SERIES SELECTION & TIME WINDOW
# ============================================================
if len(dfs) == 1:
    all_labels = sorted(cols_by_label_list[0].keys(), key=str.lower)
else:
    all_labels = sorted(set(cols_by_label_list[0].keys()).union(cols_by_label_list[1].keys()), key=str.lower)

st.sidebar.markdown("---")
select_all = st.sidebar.checkbox("Select all series", True)
selected_labels = all_labels[:] if select_all else st.sidebar.multiselect("Series:", all_labels)
if not selected_labels:
    st.stop()

st.sidebar.markdown("---")
st.sidebar.subheader("Time range")

if len(dfs) == 1:
    n = len(dfs[0])
else:
    n = min(len(dfs[0]), len(dfs[1]))

slider_first, slider_last = st.sidebar.select_slider(
    "Hour range (index)",
    options=list(range(0, n + 1)),
    value=(0, n)
)
use_manual = st.sidebar.checkbox("Fill hours manually")
if use_manual:
    first_hour = int(st.sidebar.number_input("Start hour (index)", min_value=0, max_value=max(n - 1, 0), value=slider_first))
    last_hour  = int(st.sidebar.number_input("End hour (index)",   min_value=min(first_hour + 1, n), max_value=n, value=slider_last))
else:
    first_hour, last_hour = int(slider_first), int(slider_last)

x_idx = list(range(first_hour, last_hour))

# Build views
dfs_view = [df.iloc[first_hour:last_hour] for df in dfs]

# Build series maps per DF
series_maps = []
for df_view, cols_by_label in zip(dfs_view, cols_by_label_list):
    s_map = {lab: build_series(df_view, cols_by_label, lab) for lab in selected_labels}
    series_maps.append(s_map)

# Filter labels that are not all-zero across the visible window
if len(dfs) == 1:
    nz_labels = [lab for lab in selected_labels if not is_all_zero(series_maps[0][lab])]
else:
    nz_labels = []
    for lab in selected_labels:
        nz = (not is_all_zero(series_maps[0][lab])) or (not is_all_zero(series_maps[1][lab]))
        if nz:
            nz_labels.append(lab)

if not nz_labels:
    st.info("All selected series are zero in this window.")
    st.stop()

# Sidebar customization
st.sidebar.markdown("---")
st.sidebar.subheader("Customize series")
display_names = {}
series_colors = {}
for lab in nz_labels:
    display_names[lab] = st.sidebar.text_input(f"Name — {lab}", lab)
    default_c = TECH_COLORS.get(lab, stable_color_from_name(lab))
    series_colors[lab] = st.sidebar.color_picker(f"Color — {lab}", default_c)

# Unit classification
def unit_for_label_single(cols_by_label: Dict[str, List[str]], lab: str) -> str:
    return detect_unit_type(cols_by_label.get(lab, []))

if len(dfs) == 1:
    cols_by_label = cols_by_label_list[0]
    energy_labels = [lab for lab in nz_labels if unit_for_label_single(cols_by_label, lab) == "energy"]
    mass_labels   = [lab for lab in nz_labels if unit_for_label_single(cols_by_label, lab) == "mass"]
else:
    def unit_type_for_label_dual(lab: str) -> str:
        t1 = detect_unit_type(cols_by_label_list[0].get(lab, []))
        t2 = detect_unit_type(cols_by_label_list[1].get(lab, []))
        s = {t1, t2}
        if "energy" in s: return "energy"
        if "mass" in s:   return "mass"
        return "other"
    energy_labels = [lab for lab in nz_labels if unit_type_for_label_dual(lab) == "energy"]
    mass_labels   = [lab for lab in nz_labels if unit_type_for_label_dual(lab) == "mass"]

# Plot helpers
def shared_ymax(labels, maps) -> float:
    ymax = 0.0
    for lab in labels:
        for s_map in maps:
            s = s_map.get(lab)
            if s is None:
                continue
            vmax = pd.to_numeric(s, errors="coerce").max()
            if pd.notna(vmax):
                ymax = max(ymax, float(vmax))
    return ymax if ymax > 0 else 1.0

def fig_to_png(fig, dpi=220):
    buf = io.BytesIO()
    fig.savefig(buf, format="png", bbox_inches="tight", dpi=dpi)
    buf.seek(0)
    return buf

# ============================================================
# PLOTS — ENERGY (sequential, each with legend)
# ============================================================
if energy_labels:
    st.subheader("Energy flows (kWh)")

    # Determine y-limit(s)
    if len(dfs) == 1:
        ymax_e = shared_ymax(energy_labels, [series_maps[0]])
    else:
        ymax_e = shared_ymax(energy_labels, series_maps)

    # For each scenario selected, draw one figure (sequential)
    for i in range(len(dfs)):
        fig_e, ax = plt.subplots(figsize=(13.6, 6.0))
        for lab in energy_labels:
            s = series_maps[i].get(lab)
            if s is not None:
                ax.plot(x_idx, s.values, label=display_names[lab],
                        color=series_colors[lab], linewidth=1.9)
        ax.set_ylim(0, ymax_e * 1.05)
        title = stems[i] if len(stems) > i else "Scenario"
        ax.set_title(title)
        ax.set_xlabel("Hour (index)")
        ax.set_ylabel("kWh")
        ax.grid(True)
        # Per-figure legend (outside right)
        ax.legend(loc="center left", bbox_to_anchor=(1.0, 0.5), frameon=False)
        plt.subplots_adjust(right=0.80)
        st.pyplot(fig_e, use_container_width=True)
        st.download_button(
            f"Download Energy — {title}",
            data=fig_to_png(fig_e),
            file_name=f"energy_{title}_{first_hour}_{last_hour-1}.png",
            mime="image/png",
        )
else:
    st.info("No energy (kWh) series in this window.")

# ============================================================
# PLOTS — MASS (sequential, each with legend)
# ============================================================
if mass_labels:
    st.subheader("Mass flows (kg)")

    # Determine y-limit(s)
    if len(dfs) == 1:
        ymax_m = shared_ymax(mass_labels, [series_maps[0]])
    else:
        ymax_m = shared_ymax(mass_labels, series_maps)

    # For each scenario selected, draw one figure (sequential)
    for i in range(len(dfs)):
        fig_m, ax = plt.subplots(figsize=(13.6, 6.0))
        for lab in mass_labels:
            s = series_maps[i].get(lab)
            if s is not None:
                ax.plot(x_idx, s.values, label=display_names[lab],
                        color=series_colors[lab], linewidth=1.9)
        ax.set_ylim(0, ymax_m * 1.05)
        title = stems[i] if len(stems) > i else "Scenario"
        ax.set_title(title)
        ax.set_xlabel("Hour (index)")
        ax.set_ylabel("kg")
        ax.grid(True)
        # Per-figure legend (outside right)
        ax.legend(loc="center left", bbox_to_anchor=(1.0, 0.5), frameon=False)
        plt.subplots_adjust(right=0.80)
        st.pyplot(fig_m, use_container_width=True)
        st.download_button(
            f"Download Mass — {title}",
            data=fig_to_png(fig_m),
            file_name=f"mass_{title}_{first_hour}_{last_hour-1}.png",
            mime="image/png",
        )
else:
    st.info("No mass (kg) series in this window.")

st.info(f"Showing hours from {first_hour} to {last_hour-1}")