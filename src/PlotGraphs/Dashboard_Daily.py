import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import os
from pathlib import Path



# =============================================
# Daily Series Dashboard
# ---------------------------------------------
# This dashboard allows users to select a daily scenario CSV file,
# choose the time range and series to plot, and visualize them with
# consistent formatting and legend placement.
#
# Features:
# - Select scenario from a folder
# - Select time range (start/end hour)
# - Select series to plot (none selected by default)
# - Line plot with legend outside the plot (right)
# - Auto-adjusted vertical scale
# - Clean axis labels and minimal margins
# =============================================

st.set_page_config(page_title="Daily Series Dashboard", layout="wide")

# Default folder for the scenarios (adjust if needed)
DEFAULT_FLOWS_FOLDER = r"C:\GitHub\OptiPlant.jl\results\Greenlab\All_fuels_PhD\Hourly results\Flows"

# Allow the user to choose the folder containing daily scenario CSV files
flows_folder_input = st.sidebar.text_input("Results folder (folder with CSVs)", DEFAULT_FLOWS_FOLDER)
flows_folder = Path(flows_folder_input)

# Validate folder and list CSV files
if not flows_folder.exists() or not flows_folder.is_dir():
    st.sidebar.error(f"Folder not found: {flows_folder}")
    st.stop()

csv_files = [p.name for p in sorted(flows_folder.glob('*.csv'))]
if not csv_files:
    st.sidebar.warning(f"No CSV files found in {flows_folder}")
    st.stop()


# Sidebar: scenario selection
st.sidebar.title("Scenario Options")
selected_file = st.sidebar.selectbox("Select scenario:", csv_files)


# Read the selected CSV file
csv_path = flows_folder / selected_file
df = pd.read_csv(csv_path)


# Detect time column (first with 'time' or 'hour', else first column)
possible_time_cols = [col for col in df.columns if 'time' in col.lower() or 'hour' in col.lower()]
time_col = possible_time_cols[0] if possible_time_cols else df.columns[0]


# Sidebar: select time range
first_hour = st.sidebar.number_input("Start hour (index)", min_value=0, max_value=len(df)-1, value=0)
last_hour = st.sidebar.number_input("End hour (index)", min_value=first_hour+1, max_value=len(df), value=len(df))

# Selección de series


# Sidebar: select series to plot (none selected by default)
series_cols = [col for col in df.columns if col != time_col]
selected_series = st.sidebar.multiselect("Series to show:", series_cols, default=[])

# Series customization: rename and color
st.sidebar.markdown("---")
st.sidebar.subheader("Customize selected series")
display_names = {}
series_colors = {}
for i, col in enumerate(selected_series):
    use_original = st.sidebar.checkbox(f"Use original name for '{col}'", value=True, key=f"use_orig_daily_{i}")
    if use_original:
        display_name = col
        st.sidebar.text_input(f"Display name for {col}", value=str(col), key=f"daily_name_{i}")
    else:
        display_name = st.sidebar.text_input(f"Display name for {col}", value=str(col), key=f"daily_name_{i}")
    default_color = "#%06x" % (abs(hash(col)) & 0xFFFFFF)
    color = st.sidebar.color_picker(f"Color for {col}", value=default_color, key=f"daily_color_{i}")
    display_names[col] = display_name
    series_colors[col] = color



# Main plot area
st.title(f"Daily Series Dashboard - {selected_file}")
if selected_series:
    # Create the plot
    fig, ax = plt.subplots(figsize=(10, 6))
    ymax = 0
    for col in selected_series:
        label = display_names.get(col, col)
        color = series_colors.get(col, None)
        ax.plot(df[time_col].iloc[first_hour:last_hour], df[col].iloc[first_hour:last_hour], label=label, color=color)
        ymax = max(ymax, df[col].iloc[first_hour:last_hour].max())
    # Auto-adjust vertical scale
    if ymax <= 0:
        ymax = 1
    ax.set_ylim(bottom=0, top=ymax * 1.05)
    ax.set_xlabel(time_col)
    ax.set_ylabel("Value")
    ax.set_title(f"Selected Series from {selected_file}")
    # Legend on the right, outside the plot (only if there are labels)
    handles, labels = ax.get_legend_handles_labels()
    if labels:
        ax.legend(loc='center left', bbox_to_anchor=(1.0, 0.5))
    plt.subplots_adjust(left=0.12, right=0.80, top=0.92, bottom=0.15)
    ax.grid(True)
    st.pyplot(fig)
    # Download button for PNG
    import io
    buf = io.BytesIO()
    fig.savefig(buf, format='png', bbox_inches='tight')
    buf.seek(0)
    st.download_button(label="Download chart as PNG", data=buf, file_name=f"daily_series_{os.path.splitext(selected_file)[0]}.png", mime="image/png")
    st.info(f"Showing hours from {first_hour} to {last_hour-1}")
else:
    st.info("Select series in the sidebar to display the plot.")

# =============================================
# Usage:
# 1. Install streamlit: pip install streamlit
# 2. Run: streamlit run src/PlotGraphs/Dashboard_Daily.py
# =============================================

