
# =============================================
# Scenario Comparison Dashboard (Stacked Bars)
# ---------------------------------------------
# This dashboard allows users to compare multiple scenarios (CSV files)
# and visualize selected technology values as stacked bars.
#
# Features:
# - Select scenarios from a results folder
# - Select the concept/column to compare (e.g., CAPEX, Installed Capacity)
# - Select technologies to include (none selected by default)
# - Stacked bar chart with legend outside the plot
# - Clean axis labels and minimal margins
# =============================================

import streamlit as st
import pandas as pd
import os
import matplotlib.pyplot as plt
from pathlib import Path

# Get the folder where this script is located
default_folder = Path.cwd() / "results" / "Example" / "Results_example" / "Main results"

main_results_folder = st.text_input(
    "Enter 'Main results' folder path:",
    value=str(default_folder)  # pre-fill with default
)

csv_files = [] 

if main_results_folder:  # Only run if user entered something
    folder_path = Path(main_results_folder)
    if folder_path.exists() and folder_path.is_dir():
        csv_files = [f for f in os.listdir(folder_path) 
                     if f.lower().startswith('scenario') and f.lower().endswith('.csv')]
        if csv_files:
            st.success(f"Found {len(csv_files)} scenario CSV files in the folder")

st.sidebar.title("Scenario Options")
selected_files = st.sidebar.multiselect("Select scenarios:", csv_files, default=[])

# Read all selected scenario files
dfs = {}
for file in selected_files:
    path = os.path.join(main_results_folder, file)
    dfs[file] = pd.read_csv(path)

# Find common columns to compare
if dfs:
    common_cols = set.intersection(*(set(df.columns) for df in dfs.values()))
else:
    common_cols = set()

# Exclude irrelevant columns
exclude_cols = [col for col in common_cols if any(x in col.lower() for x in ['id','name','site','scenario'])]
compare_cols = [col for col in common_cols if col not in exclude_cols]

selected_col = st.sidebar.selectbox(
    "Select result to compare across scenarios (e.g., CAPEX, Installed Capacity):",
    compare_cols if compare_cols else [""],
    index=0
)

# Detect technology column ('Type of unit', 'Type of unit\n', 'Technology')
tech_col = None
for col_candidate in ['Type of unit', 'Type of unit\n', 'Technology']:
    if dfs and all(col_candidate in df.columns for df in dfs.values()):
        tech_col = col_candidate
        break

# Get available technologies
techs = set()
for df in dfs.values():
    if tech_col and tech_col in df.columns:
        techs.update(df[tech_col].dropna().unique())
    else:
        techs.update(df.index)
techs = list(techs)

# No technologies selected by default
selected_techs = st.sidebar.multiselect("Technologies to include:", techs, default=techs)

# Allow user to rename and pick colors for selected technologies
st.sidebar.markdown("---")
st.sidebar.subheader("Customize selected technologies")
custom_names = {}
custom_colors = {}
for i, tech in enumerate(selected_techs):
    # checkbox to use original name (default True)
    use_original = st.sidebar.checkbox(f"Use original name for '{tech}'", value=True, key=f"use_orig_{i}")
    if use_original:
        display_name = tech
        # still show a disabled text input so user sees the original name but can't edit
        st.sidebar.text_input(f"Display name for {tech}", value=str(tech), key=f"name_{i}")
    else:
        display_name = st.sidebar.text_input(f"Display name for {tech}", value=str(tech), key=f"name_{i}")

    # color picker (default derived from hash but stable per index)
    default_color = "#%06x" % (abs(hash(tech)) & 0xFFFFFF)
    color = st.sidebar.color_picker(f"Color for {tech}", value=default_color, key=f"color_{i}")
    custom_names[tech] = display_name
    custom_colors[tech] = color

# Build data for the plot
bar_data = {}
for scen, df in dfs.items():
    if tech_col and tech_col in df.columns:
        df_filtered = df[df[tech_col].isin(selected_techs)]
        values = df_filtered.set_index(tech_col)[selected_col].reindex(selected_techs).fillna(0)
    else:
        values = df[selected_col].reindex(selected_techs).fillna(0)
    bar_data[scen] = values

# Create DataFrame for plotting
plot_df = pd.DataFrame(bar_data)

st.title("Scenario Comparison - Stacked Bar Chart")
if selected_files:
    st.write(f"Comparing: {', '.join(selected_files)}")

    fig, ax = plt.subplots(figsize=(10, 6))
    bottom = [0]*len(plot_df.columns)
    for tech in selected_techs:
        label = custom_names.get(tech, tech)
        color = custom_colors.get(tech, None)
        ax.bar(plot_df.columns, plot_df.loc[tech], label=label, bottom=bottom, color=color)
        bottom = [b + v for b, v in zip(bottom, plot_df.loc[tech])]

    # Set y-axis limits automatically so all bars are visible
    ymax = max(bottom) if bottom else 0
    if ymax <= 0:
        ymax = 1
    ax.set_ylim(0, ymax * 1.05)

    ax.set_ylabel(selected_col if selected_col else "Value")
    ax.set_xlabel("Scenario")
    ax.set_title(f"{selected_col} by Technology and Scenario")
    # Legend outside the plot (right) only if there are labels
    handles, labels = ax.get_legend_handles_labels()
    if labels:
        ax.legend(loc='center left', bbox_to_anchor=(1.0, 0.5))
    # Reduce margins
    plt.subplots_adjust(left=0.12, right=0.80, top=0.92, bottom=0.15)
    st.pyplot(fig)

    # Provide a download button for the PNG image
    import io
    buf = io.BytesIO()
    fig.savefig(buf, format='png', bbox_inches='tight')
    buf.seek(0)
    st.download_button(label="Download chart as PNG", data=buf, file_name="scenario_comparison.png", mime="image/png")
else:
    st.info("Select scenarios and technologies in the sidebar to compare.")