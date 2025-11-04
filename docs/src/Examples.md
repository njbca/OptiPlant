#- Examples- and- Troubleshooting

This- section- provides- practical- examples- and- solutions- to- common- issues- when- using- OptiPlant.

##- Complete- Workflow- Example

###- Step- 1:- Setup- and- Installation

After- following- the- [Installation- Guide](installation.md):

1.- **Download- OptiPlant**- from- GitHub- (Code- →- Download- ZIP)
2.- **Extract**- to- your- preferred- location- - 
3.- **Activate- Julia- environment**:
- - - ```julia
- - - ]- activate- env
- - - status- - #- verify- packages- installed
- - - ```

###- Step- 2:- Basic- Model- Run

1.- **Navigate**- to- the- OptiPlant-master- folder
2.- **Open**- `RUN- CODE/Main.jl`- in- VS- Code
3.- **Configure- the- solver**- (line- 4):
- - - ```julia
- - - solver- =- "HiGHS"
- - - ```
4.- **Set- paths**- (lines- 22-25):
- - - ```julia
- - - OptiPlant_directory- =- "C:/Users/your-path/OptiPlant-master"
- - - input_data_file- =- "Input_data_example"
- - - input_sheet_name- =- "Data_base_case"- - 
- - - results_folder- =- "Results_base_case"
- - - ```
5.- **Run**- the- file- (typical- solve- time:- <5- minutes)

###- Step- 3:- View- Results

1.- **Navigate**- to- `BASE/Results/Results_base_case/`
2.- **Copy**- the- `Results.xlsx`- file- into- this- folder
3.- **Open**- Results.xlsx- and- go- to- "Import"- sheet
4.- **Set- directories**:
- - - -- Main- results- folder:- `C:/path/to/Results_base_case/Main- results/`
- - - -- Hourly- results- folder:- `C:/path/to/Results_base_case/Hourly- results/`
- - - -- **Important**:- Paths- must- end- with- `\`
5.- **Run- macros**- to- import- data
6.- **View- results**- in- scenario- sheets- and- "All_scenarios"- sheet

##- Practical- Examples

###- Example- 1:- Ammonia- Production- Analysis

**Objective**:- Compare- different- electrolyzer- technologies- for- NH₃- production

**Steps**:
1.- **Open**- `BASE/Data/Inputs/Input_data_example.xlsx`
2.- **Modify**- "Selected_units"- sheet:
- - - -- Set- electrolyzer- options- (1- =- include,- 0- =- exclude)
- - - -- Keep- NH₃- synthesis- units- =- 1
3.- **Update**- "ScenariosToRun"- sheet:
- - - -- Add- scenarios- with- different- electrolyzer- technologies
4.- **Run**- Main.jl- with- updated- scenario- sheet- reference
5.- **Compare**- results- using- Pivot- Tables- in- Results.xlsx

###- Example- 2:- Location- Assessment- - 

**Objective**:- Evaluate- hydrogen- production- potential- across- different- locations

**Steps**:
1.- **Prepare- profiles**:- Ensure- wind/solar- profiles- available- for- target- locations
2.- **Configure- scenarios**:- Set- different- location- parameters- in- ScenariosToRun
3.- **Modify**- Selected_units- for- H₂- production- (disable- NH₃,- MeOH- units)
4.- **Run- analysis**- for- each- location
5.- **Compare**- production- costs- and- capacity- factors

###- Example- 3:- Sensitivity- Analysis

**Objective**:- Study- impact- of- electricity- prices- on- production- economics

**Steps**:
1.- **Create- price- variants**- in- Profiles/Price- sheets- - 
2.- **Define- scenarios**- with- different- price- assumptions
3.- **Use**- Scenarios_definition- sheet- for- systematic- parameter- variations
4.- **Analyze**- cost- sensitivity- using- Excel- Pivot- Tables

##- Troubleshooting

###- Common- Errors- and- Solutions

####- ERROR:- Package- X- not- found

**Symptoms**:
```
ERROR:- ArgumentError:- Package- JuMP- not- found- in- current- path
```

**Likely- Causes**:
-- Environment- not- activated- before- running- code
-- Package- not- installed
-- Package- not- called- in- code

**Solution**:
1.- **Enter- package- manager**:- Press- `]`- in- Julia- REPL
2.- **Activate- environment**:- 
- - - ```julia
- - - activate- env
- - - ```
3.- **Check- installed- packages**:
- - - ```julia
- - - status
- - - ```
4.- **Install- missing- packages**:
- - - ```julia
- - - add- JuMP- - #- or- other- missing- package
- - - ```
5.- **Verify- code- includes- necessary- packages**- at- the- beginning:
- - - ```julia
- - - using- JuMP
- - - using- HiGHS- - 
- - - using- DataFrames
- - - using- CSV
- - - using- XLSX
- - - ```

####- ERROR:- File- not- found- "no- such- file- or- directory"

**Symptoms**:
```
ERROR:- SystemError:- opening- file- "Input_data_example.xlsx":- No- such- file- or- directory
```

**Likely- Causes**:
-- Incorrect- paths/routing- between- Julia- scripts- and- Excel- sheets- in- Main.jl

**Solution**:
1.- **Verify- file- and- folder- paths**- in- Main.jl- are- correctly- set:
- - - -- Solver- line- (line- 4)
- - - -- Directories- (lines- 22-25)- 
- - - -- Scenario- sheet- name- if- changed
2.- **Use- absolute- paths**- when- possible
3.- **Pay- attention- to- folder- structure**- -- many- folders/subfolders- require- careful- routing
4.- **Check- file- extensions**- (.xlsx,- .jl)- are- correct
5.- **Verify- Excel- file- names**- match- exactly- (case-sensitive)

####- ERROR:- Format- error- when- displaying- simulation- results- in- Excel

**Symptoms**:
-- After- importing- "main- results"- CSV,- results- appear- unrealistic/too- large
-- Numbers- formatted- incorrectly- due- to- CSV- parsing

**Diagnosis**:
1.- **Open- CSV- file**- from- "Main- results"- in- text- editor
2.- **Verify- format**:- CSV- uses- commas- to- separate- cells- and- dots- for- decimals

**Solution- -- Excel- Settings**:
1.- **File- →- Options- →- Advanced**:
- - - -- Set- "Decimal- separator"- to- dot- (.)
- - - -- Set- thousands- separator- to- none- or- symbol- other- than- dot- (e.g.,- apostrophe- ')

2.- **Home- →- Number**:
- - - -- Open- Number- format- dialog- (bottom-right- of- Number- group)
- - - -- Untick- "Use- 1000- separator"

3.- **Restart- Excel**- and- re-import- data
4.- **Results- should- now- display- correctly**

###- Installation- Problems

####- Julia- or- VS- Code- Not- Recognized

**Problem**:- Command- line- doesn't- recognize- `julia`- command

**Solution**:
-- **Julia**:- Ensure- "Add- to- PATH"- was- selected- during- installation
-- **VS- Code**:- Ensure- "Add- to- PATH- (requires- shell- restart)"- was- selected
-- **Restart**- system- after- installation
-- **Manual- PATH- setup**- if- needed- (system-specific)

####- Gurobi- License- Issues

**Problem**:- Gurobi- solver- not- working- despite- installation

**Solution**:
1.- **Verify- license- activation**:- Ensure- `grbgetkey- <your-key>`- was- run- in- Command- Prompt
2.- **Check- license- location**:- Save- license- to- default- location
3.- **Restart- system**- after- Gurobi- installation
4.- **Test- license**- in- Gurobi- directly- before- using- in- Julia

###- Runtime- Issues

####- Long- Solve- Times

**Potential- Causes**:
-- Large- problem- size
-- Solver- configuration
-- System- resources

**Solutions**:
-- **Verify- solver- choice**:- HiGHS- vs- Gurobi- performance- comparison
-- **Check- system- resources**:- Close- other- applications
-- **Problem- scaling**:- Start- with- smaller- scenarios
-- **Hardware**:- Ensure- adequate- RAM- (>8GB- recommended- for- large- problems)

####- Memory- Issues

**Symptoms**:- Julia- crashes- or- runs- out- of- memory

**Solutions**:
-- **Increase- Julia- heap**:- `julia- --heap-size-hint=8G`
-- **Close- other- applications**- before- running
-- **Use- 64-bit- Julia**- for- large- problems
-- **Process- scenarios- separately**- instead- of- batch- runs

###- Performance- Tips

####- General- Recommendations

1.- **HiGHS- solver**:- Recommended- for- most- users- (open-source,- reliable)
2.- **Typical- solve- time**:- Under- 5- minutes- on- personal- computer
3.- **Environment- consistency**:- Always- activate- `env`- environment
4.- **File- organization**:- Keep- consistent- naming- across- Excel- sheets

####- Optimization- Strategies

1.- **Start- small**:- Test- with- single- scenario- before- batch- runs
2.- **Verify- inputs**:- Check- data- consistency- before- optimization
3.- **Incremental- changes**:- Modify- one- parameter- at- a- time- for- debugging
4.- **Backup- configurations**:- Keep- working- configurations- as- templates

###- Getting- Additional- Help

####- Resources

1.- **Installation- errors**:- Check- official- installation- guides- for- each- program
2.- **OptiPlant-specific- issues**:- Refer- to- this- troubleshooting- section
3.- **General- programming**:- Use- internet- forums- or- AI- tools- - 
4.- **Last- resort**:- Contact- model- authors

####- Best- Practices- for- Help- Requests

1.- **Include- error- messages**:- Copy- exact- error- text
2.- **Describe- steps**:- What- you- were- trying- to- do
3.- **System- information**:- OS,- Julia- version,- solver- used
4.- **Reproducible- example**:- Minimal- case- that- shows- the- problem

####- Community- Resources

-- **Julia- Discourse**:- https://discourse.julialang.org/
-- **JuMP- Community**:- https://jump.dev/JuMP.jl/stable/
-- **GitHub- Issues**:- https://github.com/njbca/OptiPlant/issues

##- Final- Notes

###- Important- Considerations

-- **Linear- deterministic- model**:- Perfect- foresight- assumption
-- **Yearly- fuel- demand**:- Must- be- fulfilled- as- constraint
-- **Installation- dependencies**:- Follow- official- guides- for- each- component
-- **Backup- strategy**:- Keep- copies- of- working- configurations

###- Limitations

-- **Model- type**:- Linear- programming- with- perfect- foresight
-- **Scope**:- Focused- on- fuel- production- cost- minimization- - 
-- **Data- requirements**:- Requires- comprehensive- input- data- preparation
-- **Solver- dependency**:- Requires- properly- configured- optimization- solver

###- Best- Practices- Summary

1.- **Keep- standard- Input- copies**- for- reverting- changes
2.- **Maintain- consistent- naming**- across- Excel- sheets- and- Main.jl
3.- **Activate- Julia- environment**- each- session
4.- **Verify- package- installation**- with- `status`- command
5.- **Refresh- Excel- Pivot- Tables**- after- importing- new- results
6.- **Use- descriptive- folder- names**- for- different- study- cases

##- Next- Steps

-- **[API- Reference](api.md)**- -- Technical- details- and- file- specifications
-- **[Usage- Guide](usage.md)**- -- Return- to- file- structure- documentation- - 
-- **[Installation](installation.md)**- -- Reinstall- components- if- needed
