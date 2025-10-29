import numpy as np
import matplotlib.pyplot as plt
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

dk_og_aec = os.path.join(os.path.dirname(__file__), 'Scenario_1.csv')
df_dk_og_aec = pd.read_csv(dk_og_aec)
dk_si_aec = os.path.join(os.path.dirname(__file__), 'Scenario_4.csv')
df_dk_si_aec = pd.read_csv(dk_si_aec)
dk_og_soec = os.path.join(os.path.dirname(__file__), 'Scenario_10.csv')
df_dk_og_soec = pd.read_csv(dk_og_soec)
dk_si_soec = os.path.join(os.path.dirname(__file__), 'Scenario_7.csv')
df_dk_si_soec = pd.read_csv(dk_si_soec)

ch_og_aec = os.path.join(os.path.dirname(__file__), 'Scenario_3.csv')
df_ch_og_aec = pd.read_csv(ch_og_aec)
ch_si_aec = os.path.join(os.path.dirname(__file__), 'Scenario_6.csv')
df_ch_si_aec = pd.read_csv(ch_si_aec)
ch_og_soec = os.path.join(os.path.dirname(__file__), 'Scenario_12.csv')
df_ch_og_soec = pd.read_csv(ch_og_soec) 
ch_si_soec = os.path.join(os.path.dirname(__file__), 'Scenario_9.csv')
df_ch_si_soec = pd.read_csv(ch_si_soec)

au_og_aec = os.path.join(os.path.dirname(__file__), 'Scenario_2.csv')
df_au_og_aec = pd.read_csv(au_og_aec)
au_si_aec = os.path.join(os.path.dirname(__file__), 'Scenario_5.csv')
df_au_si_aec = pd.read_csv(au_si_aec)
au_og_soec = os.path.join(os.path.dirname(__file__), 'Scenario_11.csv')
df_au_og_soec = pd.read_csv(au_og_soec) 
au_si_soec = os.path.join(os.path.dirname(__file__), 'Scenario_8.csv')  
df_au_si_soec = pd.read_csv(au_si_soec)


def get_cost(df, unit_type):
    return df.loc[df["Type of unit"] == unit_type, "Cost per unit (MEUR)"].iloc[0]

dataframes = [
    # Off-grid
    [
        [df_ch_og_aec, df_ch_og_soec],  # Northern Chile
        [df_dk_og_aec, df_dk_og_soec],  # Denmark
        [df_au_og_aec, df_au_og_soec],  # South Australia
    ],
    # Semi-islanded
    [
        [df_ch_si_aec, df_ch_si_soec],
        [df_dk_si_aec, df_dk_si_soec],
        [df_au_si_aec, df_au_si_soec],
    ]
]

# Extraer el valor de "Production cost fuel (EUR/MWhNH3)" de la primera fila para ambos (AEC y SOEC)
def get_production_cost(df):
    return df["Production cost fuel (EUR/MWhNH3)"].iloc[0]

production_costs = np.zeros((2, 3, 2))
for s_idx in range(2):
    for p_idx in range(3):
        for t_idx in range(2):
            df = dataframes[s_idx][p_idx][t_idx]
            production_costs[s_idx, p_idx, t_idx] = get_production_cost(df)



# Plot puntos en eje secundario derecho

# Aplanar para graficar
prod_cost_flat = production_costs.flatten()

# List of unit types for each layer
unit_types = {
    "solar": "Solar tracking",
    "wind_hh100": "ON_SP198-HH100",
    "wind_hh150": "ON_SP198-HH150",
    "grid": "Electricity from the grid",
    "electrolyser": ["Electrolysers AEC", "Electrolysers SOEC heat integrated"],
    "ammonia_plant": ["NH3 plant + ASU with AEC", "NH3 plant + ASU with SOEC"],
    "H2Storage": "H2 storage (buried pipes)",
    "Batteries": "Batteries",
    "Desalination": "Water supply (desalination plant)"
}

# Function to build arrays for each layer
def build_array(unit_type):
    arr = np.zeros((2, 3, 2))
    for s_idx in range(2):
        for p_idx in range(3):
            for t_idx in range(2):
                df = dataframes[s_idx][p_idx][t_idx]
                if isinstance(unit_type, list):
                    arr[s_idx, p_idx, t_idx] = get_cost(df, unit_type[t_idx])
                else:
                    arr[s_idx, p_idx, t_idx] = get_cost(df, unit_type)
    return arr

solar = build_array(unit_types["solar"])
wind_hh100 = build_array(unit_types["wind_hh100"])
wind_hh150 = build_array(unit_types["wind_hh150"])
grid = build_array(unit_types["grid"])
electrolyser = build_array(unit_types["electrolyser"])
ammonia_plant = build_array(unit_types["ammonia_plant"])
H2Storage = build_array(unit_types["H2Storage"])
Batteries = build_array(unit_types["Batteries"])
Desalination = build_array(unit_types["Desalination"])

layers = [
    ("Solar tracking", solar, "gold"),
    ("Wind onshore (HH100)", wind_hh100, "royalblue"),
    ("Wind onshore (HH150)", wind_hh150, "steelblue"),
    ("Grid", grid, "gray"),
    ("Electrolyser", electrolyser, "lightgray"),
    ("Ammonia plant",ammonia_plant,"green"),
    ("H2 Storage", H2Storage, "red"),
    ("Batteries", Batteries, "orange"),
    ("Desalination", Desalination, "purple")

]

# ===============================
# Plot
# ===============================
n_scen = len(scenarios)
n_places = len(places)
n_techs = len(techs)

fig, ax = plt.subplots(figsize=(14,6))
bar_width = 0.5
x = []
prod_cost_points = []
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
            # Guardar posición y valor de costo de producción
            x.append(i)
            prod_cost_points.append(production_costs[s_idx, p_idx, t_idx])
            i += 1

# ===============================
# Etiquetas multinivel con brackets
# ===============================
ax.set_xticks([])  # quitamos etiquetas directas en el eje X
ax.set_ylabel("Installed capacities in MW")
ax.set_title("Installed capacities by scenario, place and technology")
ax.legend(loc="upper right")

ax2 = ax.twinx()
ax2.scatter(x, prod_cost_points, color="black", marker="o", label="Production cost SOEC (EUR/MWhNH3)", zorder=10)
ax2.set_ylabel("Production cost SOEC (EUR/MWhNH3)")
ax2.set_ylim(bottom=-150)
ax2.legend(loc="upper left")


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
