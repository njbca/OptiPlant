import simeasren as sr

def create_csv_profiles(location):

    pv_parameters = sr.load_pv_setup_from_meas_file(location)
    pvgis_data = sr.download_pvgis_data(location, pv_parameters)