#Lcia normalization factors for regionalized EF v3.1
#Source:  https://publications.jrc.ec.europa.eu/repository/bitstream/JRC130796/JRC130796_01.pdf  

Lcia_EF_normalisation_factors = Dict(
    :acidification => 55.6,                         # mol H+ eq./person
    :climate_change => 7550.0,                     # kg CO2 eq/person
    :climate_change_biogenic => 7550.0,            # kg CO2 eq/person
    :climate_change_fossil => 7550.0,              # kg CO2 eq/person
    :climate_change_land_use => 7550.0,            # kg CO2 eq/person
    :ecotoxicity_freshwater => 56700.0,            # CTUe/person
    :ecotoxicity_freshwater_inorganics => 56700.0, # CTUe/person
    :ecotoxicity_freshwater_organics => 56700.0,   # CTUe/person
    :energy_resources_non_renewable => 65000.0,    # MJ/person
    :eutrophication_freshwater => 1.61,            # kg P eq./person
    :eutrophication_marine => 19.5,                # kg N eq./person
    :eutrophication_terrestrial => 177.0,          # mol N eq./person
    :human_toxicity_carcinogenic => 0.0000173,     # CTUh/person
    :human_toxicity_carcinogenic_inorganics => 0.0000173, # CTUh/person
    :human_toxicity_carcinogenic_organics => 0.0000173,   # CTUh/person
    :human_toxicity_non_carcinogenic => 0.000129,         # CTUh/person
    :human_toxicity_non_carcinogenic_inorganics => 0.000129, # CTUh/person
    :human_toxicity_non_carcinogenic_organics => 0.000129,   # CTUh/person
    :ionising_radiation_human_health => 4220.0,    # kBq U235 eq./person
    :land_use => 819000.0,                         # pt/person
    :material_resources_metals_minerals => 0.0636, # kg Sb eq./person
    :ozone_depletion => 0.0523,                    # kg CFC-11 eq/person
    :particulate_matter_formation => 0.000595,     # disease incidences/person
    :photochemical_oxidant_formation_human_health => 40.9, # kg NMVOC eq./person
    :water_use => 11500.0                          # m³ water eq. of deprived water/person
)
