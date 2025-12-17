module Import_profiles_data

using PythonCall

export import_profiles

# Python directory
const PYTHON_DIR = joinpath(@__DIR__, "..", "..", "python")

function load_python_module()
    sys = pyimport("sys")
    sys.path.insert(0, PYTHON_DIR)
    import_profiles_py = pyimport("imports.import_profiles")
    return import_profiles_py
end


function import_profiles(location::String)
    import_profiles_py = load_python_module()  # This will load the module when needed
    import_profiles_py.create_csv_profiles(location)
    return nothing
end

end