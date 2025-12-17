module Launch_dashboards

using PythonCall

export launch_scenario_dashboard, launch_hourly_profiles_dashboard, launch_lcia_dashboard

function launch_scenario_dashboard()

    # Python directory and Streamlit app path
    PYTHON_DIR = joinpath(@__DIR__, "..", "..", "python")
    app_path = joinpath(PYTHON_DIR, "plotgraphs", "dashboard_scenarios.py")

    run(`streamlit run $app_path --server.headless=true`, wait = false)

    if Sys.iswindows()
        run(`cmd /c start http://localhost:8501`, wait=false)
    elseif Sys.isapple()
        run(`open http://localhost:8501`, wait=false)
    else
        run(`xdg-open http://localhost:8501`, wait=false)
    end
    return nothing
end

function launch_hourly_profiles_dashboard()

    # Python directory and Streamlit app path
    PYTHON_DIR = joinpath(@__DIR__, "..", "..", "python")
    app_path = joinpath(PYTHON_DIR, "plotgraphs", "dashboard_daily.py")

    run(`streamlit run $app_path --server.headless=true`, wait = false)

    if Sys.iswindows()
        run(`cmd /c start http://localhost:8501`, wait=false)
    elseif Sys.isapple()
        run(`open http://localhost:8501`, wait=false)
    else
        run(`xdg-open http://localhost:8501`, wait=false)
    end
    return nothing
end

function launch_lcia_dashboard()

    # Python directory and Streamlit app path
    PYTHON_DIR = joinpath(@__DIR__, "..", "..", "python")
    app_path = joinpath(PYTHON_DIR, "plotgraphs", "dashboard_lcia.py")

    run(`streamlit run $app_path --server.headless=true`, wait = false)

    if Sys.iswindows()
        run(`cmd /c start http://localhost:8501`, wait=false)
    elseif Sys.isapple()
        run(`open http://localhost:8501`, wait=false)
    else
        run(`xdg-open http://localhost:8501`, wait=false)
    end
    return nothing
end

end