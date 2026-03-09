To use the data analysis dashboards and analyze the results write in the powershell terminal:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m streamlit run result_analysis_dashboards/dashboard_scenarios.py
python -m streamlit run result_analysis_dashboards/dashboard_hourly.py
```

If there is some authorization errors when activating the environment, in powershell try:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Make sure to update the result folder in the dahsboard python scripts: 

# Result folder (you can adjust this fallback)
main_results_folder = Path.cwd() / "results" / "Full_model" / "GLS_analysis" / "Main results"