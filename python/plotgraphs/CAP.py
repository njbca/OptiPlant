import numpy as np
import matplotlib.pyplot as plt
import csv
import pandas as pd
import os
# ===============================
# Datos
# ===============================

scenarios = ["Off-grid", "Semi-islanded"]
places = ["Northern Chile\n(solar+)", "Denmark\n(wind+)", "South Australia\n(wind/solar)"]
techs = ["AEC", "SOEC"]

# ===============================
# archivos
# ===============================

# Helper to load CSVs
def load_csv(filename):
    path = os.path.join(os.path.dirname(__file__), filename)
    return pd.read_csv(path)

# Map for scenario files
scenario_files = {
    ("chile", "Off-grid", "AEC"): "Scenario_3.csv",
    ("chile", "Off-grid", "SOEC"): "Scenario_12.csv",
    ("chile", "Semi-islanded", "AEC"): "Scenario_6.csv",
    ("chile", "Semi-islanded", "SOEC"): "Scenario_9.csv",
    ("denmark", "Off-grid", "AEC"): "Scenario_1.csv",
    ("denmark", "Off-grid", "SOEC"): "Scenario_10.csv",
    ("denmark", "Semi-islanded", "AEC"): "Scenario_4.csv",
    ("denmark", "Semi-islanded", "SOEC"): "Scenario_7.csv",
    ("australia", "Off-grid", "AEC"): "Scenario_2.csv",
    ("australia", "Off-grid", "SOEC"): "Scenario_11.csv",
    ("australia", "Semi-islanded", "AEC"): "Scenario_5.csv",
    ("australia", "Semi-islanded", "SOEC"): "Scenario_8.csv",
}

# Place keys for easier mapping
place_keys = ["chile", "denmark", "australia"]

# Load all dataframes in a nested dict
dfs = {
    scen: {
        place: {
            tech: load_csv(scenario_files[(place, scen, tech)])
            for tech in techs
        }
        for place in place_keys
    }
    for scen in scenarios
}

# Helper to get installed capacity
def get_capacity(df, unit, factor=1.0):
    val = df.loc[df["Type of unit"] == unit, "Installed capacity"]
    return val.iloc[0] * factor if not val.empty else 0.0

# Build arrays
solar = np.array([
    [
        [get_capacity(dfs[scen][place][tech], "Solar tracking")
         for tech in techs]
        for place in place_keys
    ]
    for scen in scenarios
])
wind_hh100 = np.array([
    [
        [get_capacity(dfs[scen][place][tech], "ON_SP198-HH100")
         for tech in techs]
        for place in place_keys
    ]
    for scen in scenarios
])
wind_hh150 = np.array([
    [
        [get_capacity(dfs[scen][place][tech], "ON_SP198-HH150")
         for tech in techs]
        for place in place_keys
    ]
    for scen in scenarios
])
grid = np.array([
    [
        [get_capacity(dfs[scen][place][tech], "Electricity from the grid")
         for tech in techs]
        for place in place_keys
    ]
    for scen in scenarios
])
electrolyser = np.array([
    [
        [
            get_capacity(dfs[scen][place][tech], "Electrolysers AEC", 51.51)
            if tech == "AEC"
            else get_capacity(dfs[scen][place][tech], "Electrolysers SOEC heat integrated", 37.93)
            for tech in techs
        ]
        for place in place_keys
    ]
    for scen in scenarios
])

layers = [
    ("Solar tracking", solar, "gold"),
    ("Wind onshore (HH100)", wind_hh100, "royalblue"),
    ("Wind onshore (HH150)", wind_hh150, "steelblue"),
    ("Grid", grid, "gray"),
    ("Electrolyser", electrolyser, "lightgray"),
]

# ===============================
# Plot
# ===============================
n_scen = len(scenarios)
n_places = len(places)
n_techs = len(techs)

x = np.arange(n_scen * n_places * n_techs)
fig, ax = plt.subplots(figsize=(14,6))
bar_width = 0.5

i = 0
for s_idx in range(n_scen):
    for p_idx in range(n_places):
        for t_idx in range(n_techs):
            bottom = 0
            for label, arr, color in layers:
                value = arr[s_idx, p_idx, t_idx]
                ax.bar(i, value, bar_width, bottom=bottom,
                       color=color, edgecolor="black",
                       label=label if i==0 else "")
                if value > 0:
                    ax.text(i, bottom+value/2, f"{value:.2f}",
                            ha="center", va="center", fontsize=8, fontweight="bold")
                bottom += value
            i += 1

# ===============================
# Etiquetas multinivel con brackets
# ===============================
ax.set_xticks([])  # quitamos etiquetas directas en el eje X
ax.set_ylabel("Installed capacities in MW")
ax.set_title("Installed capacities by scenario, place and technology")
ax.legend(loc="upper right")


def add_bracket(start, end, y, text, line_height=0.02, fontsize=10, weight="normal"):
    ax.plot([start, end], [y, y], color="black", lw=1)
    ax.text((start+end)/2, y - line_height, text, ha="center", va="top",
            fontsize=fontsize, fontweight=weight)

ymin, ymax = ax.get_ylim()
y_text = -0.05 * ymax

# Nivel 1: Tecnologías
for i in range(len(x)):
    add_bracket(i-0.35, i+0.35, y_text, techs[i % n_techs],
                line_height=0.02, fontsize=8)

# Nivel 2: Países
y_country = y_text - 0.07*ymax
for s_idx in range(n_scen):
    for p_idx, place in enumerate(places):
        start = (s_idx*n_places + p_idx)*n_techs
        end = start + n_techs - 1
        add_bracket(start-0.35, end+0.35, y_country, place,
                    line_height=0.03, fontsize=9, weight="bold")

# Nivel 3: Escenarios
y_scen = y_text - 0.14*ymax
for s_idx, scen in enumerate(scenarios):
    start = s_idx*n_places*n_techs
    end = start + n_places*n_techs - 1
    add_bracket(start-0.5, end+0.5, y_scen, scen,
                line_height=0.04, fontsize=11, weight="bold")

plt.tight_layout()
plt.show()
