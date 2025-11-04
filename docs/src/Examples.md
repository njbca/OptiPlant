# Examples and Troubleshooting

This section provides practical examples for using OptiPlant and comprehensive troubleshooting for common issues.

## Common Errors and Solutions

### ERROR: Package X not found

![Package Environment Example](images/Fig.38.png)

**Likely Cause:**
- Environment not activated before running code
- Package not installed in current environment  
- Package not called properly in code

**Solution Steps:**

1. **Activate Environment:**
   ```julia
   ] activate env
   ```

2. **Check Installed Packages:**
   ```julia
   (env) pkg> status
   ```

![Package Manager Status](images/Fig.39.png)

3. **Install Missing Package:**
   ```julia
   (env) pkg> add PACKAGE_NAME
   ```

4. **Ensure Proper Package Calls:**
   Make sure your code includes the necessary `using` statements at the beginning:
   ```julia
   using JuMP, HiGHS, DataFrames, CSV, XLSX
   ```

**Prevention:**
- Always activate the `env` environment before running OptiPlant
- Verify package installation with `status` command
- Include all required packages in your Julia script header

### ERROR: File not found "no such file or directory"

**Likely Cause:**
- Incorrect paths/routing between Julia scripts and Excel files in Main.jl
- Missing files or moved directories
- Incorrect file naming or extensions

**Solution Steps:**

![Path Configuration](images/Fig.40.png)

1. **Verify File Paths in Main.jl:**
   Check lines 22-25 for correct paths:
   ```julia
   OptiPlant_directory = "C:/correct/path/to/OptiPlant-master"
   input_data_excel_file_name = "Input_data_example"  # No .xlsx extension
   input_data_excel_sheet_name = "ScenariosToRun"
   results_folder_name = "Results_base_case"
   ```

2. **Check File Existence:**
   - Verify Excel files exist in `BASE/Data/Inputs/`
   - Confirm profile files exist in `BASE/Data/Profiles/`
   - Ensure correct file names (case-sensitive)

![Routing Example](images/Fig.41.png)

3. **Path Format Guidelines:**
   - Use forward slashes `/` or double backslashes `\\\\`
   - Avoid spaces in folder/file names when possible
   - Use absolute paths for reliability

4. **Scenario Sheet References:**
   If you created a new scenario sheet, update Main.jl line 28:
   ```julia
   scenario_sheet_name = "YourNewSheetName"  # Update this line
   ```

**Prevention:**
- Keep consistent file naming across all components
- Use the provided folder structure without modifications
- Document any custom path changes

### ERROR: Format error when displaying simulation results in Excel

![Incorrect Results Display](images/Fig.42.png)

**Symptom:**
After importing "main results" CSV files, results appear unrealistic or extremely large numbers due to CSV parsing issues.

**Diagnosis:**
Open a CSV file from "Main results" in a text editor - you'll see the CSV uses commas to separate cells and dots for decimals:

![CSV Format Example](images/Fig.43.png)

**Solution (Excel Settings):**

#### Method 1: Excel Advanced Options

![Excel Advanced Options](images/Fig.44.png)

1. **File → Options → Advanced**
2. Set **"Decimal separator"** to dot (.)
3. Set **"Thousands separator"** to none or different symbol (e.g., apostrophe ')
4. Click OK and restart Excel

#### Method 2: Number Format Settings

![Number Format Dialog](images/Fig.45.png)

1. **Home → Number** (click small arrow in Number group)
2. **Untick "Use 1000 separator"**

![Number Format Options](images/Fig.46.png)

3. Apply changes and restart Excel
4. Re-import the CSV data

**Result After Fix:**

![Corrected Results](images/Fig.47.png)

Results should now display correctly with realistic values.

**Prevention:**
- Set correct Excel regional settings before first use
- Always verify a few result values make sense after import
- Keep Excel settings consistent across team members

## Installation Troubleshooting

### Julia Installation Issues

**Problem**: Julia not recognized in command line or VS Code

**Solutions:**
- Ensure "Add Julia to PATH" was checked during installation
- Restart computer after installation
- Reinstall Julia with administrator privileges
- Manually add Julia to system PATH if needed

### VS Code Integration Problems

**Problem**: Julia extension not working properly

**Solutions:**
- Install official Julia extension from VS Code marketplace
- Restart VS Code after Julia installation
- Use `Ctrl+Shift+P` → "Julia: Start REPL" to initialize
- Check Julia path in VS Code settings if issues persist

### Gurobi License Issues

**Problem**: Gurobi license not recognized

**Solutions:**
- Ensure license key was entered correctly in command prompt
- Verify license file location (should be in default directory)  
- Check license validity and expiration
- Contact Gurobi support for license-specific issues

## Performance Tips

### Optimization Speed

1. **Use HiGHS Solver:**
   - Recommended open-source solver
   - Typically solves problems in <5 minutes
   - Same results as commercial alternatives

2. **Model Size Management:**
   - Remove unused units in Selected_units sheet (set to 0)
   - Limit time resolution if hourly detail not needed
   - Focus scenarios on essential parameter variations

3. **Hardware Recommendations:**
   - **RAM**: 8GB+ for large models
   - **CPU**: Multi-core processors improve solving speed
   - **Storage**: SSD for faster file I/O operations

### Data Management Best Practices

1. **Scenario Organization:**
   - Group related scenarios in same Excel sheet
   - Use descriptive scenario names for result identification
   - Keep scenario count reasonable for analysis purposes

2. **Input Data Validation:**
   - Verify units are consistent across all parameters
   - Check for missing data or unrealistic values  
   - Validate profile data covers full 8760 hours

3. **Results Handling:**
   - Regular cleanup of old results folders
   - Use clear naming conventions for result folders
   - Export key results to separate files for archiving

## FAQ - Frequently Asked Questions

### General Usage

**Q: How long should OptiPlant take to solve?**
A: Typical solve times are below 5 minutes on personal computers using HiGHS solver. Larger models or older hardware may take longer.

**Q: Can I use commercial solvers other than Gurobi?**
A: OptiPlant is configured for HiGHS (open-source) and Gurobi (commercial). Both provide identical results.

**Q: What fuel types can OptiPlant model?**
A: NH₃ (ammonia), H₂ (hydrogen), and MeOH (methanol) are demonstrated examples. The model can be adapted for other Power-to-X fuels.

### Technical Questions

**Q: Can I modify the optimization objective?**
A: Yes, OptiPlant's modular design allows modification of objectives, constraints, and variables through the Julia code.

**Q: How do I add new technologies or units?**
A: Add new units in the Data_base_case sheet with appropriate parameters, then include them in Selected_units configurations.

**Q: Can I use my own renewable energy profiles?**
A: Yes, replace profile data in the Profiles Excel files with your data, maintaining the same format and structure.

### Troubleshooting Workflow

1. **Check Environment:** Ensure `env` is activated and packages installed
2. **Verify Paths:** Confirm all file paths in Main.jl are correct  
3. **Validate Data:** Check Excel files are accessible and not corrupted
4. **Test Installation:** Run simple Julia commands to verify setup
5. **Review Logs:** Check error messages for specific failure points

## Example Workflows

### Basic First Run

1. **Setup:** Complete installation and download OptiPlant
2. **Configuration:** Set paths in Main.jl for your system
3. **Execution:** Run with default scenario to verify operation
4. **Validation:** Import results and verify reasonable outputs
5. **Analysis:** Use Excel tools to examine results

### Custom Scenario Development

1. **Planning:** Define research questions and parameter variations
2. **Data Preparation:** Modify Scenarios_definition with new parameters  
3. **Scenario Definition:** Add scenarios to ScenariosToRun sheet
4. **Execution:** Run multiple scenarios with batch processing
5. **Analysis:** Compare results across scenarios using Pivot Tables

### Advanced Modifications

1. **Literature Review:** Research parameter values and validate sources
2. **Model Extension:** Add new technologies in Data_base_case  
3. **Testing:** Validate new components with simple test cases
4. **Documentation:** Update Sources sheet with new data references
5. **Version Control:** Keep backups of working configurations

## Getting Additional Help

### Documentation Resources
- **[Installation Guide](installation.md)** - Complete setup instructions
- **[File Structure Guide](usage.md)** - Detailed file organization  
- **[Technical Reference](api.md)** - Specifications and formats

### External Resources
- **Julia Community**: [https://discourse.julialang.org/](https://discourse.julialang.org/)
- **JuMP Documentation**: [https://jump.dev/JuMP.jl/stable/](https://jump.dev/JuMP.jl/stable/)
- **HiGHS Solver**: [https://highs.dev/](https://highs.dev/)

### Support Guidelines

1. **Check this troubleshooting section first**
2. **Search Julia and JuMP forums for similar issues**
3. **Use internet resources and AI tools for programming problems**
4. **Contact model authors as last resort** - provide detailed error descriptions

### Best Practices for Problem Solving

1. **Document the Problem:**
   - Note exact error messages
   - Record steps that led to the issue
   - Save relevant file states before changes

2. **Systematic Debugging:**
   - Test components individually
   - Use minimal examples to isolate issues  
   - Verify each fix before proceeding

3. **Preventive Measures:**
   - Keep backup copies of working configurations
   - Test changes incrementally
   - Maintain consistent naming conventions

---

**Problem Resolved?** You should now be able to successfully run OptiPlant and handle most common issues that arise.