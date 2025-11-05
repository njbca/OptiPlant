#- API- Reference- and- Technical- Specifications

This- section- provides- technical- details- about- OptiPlant's- data- structures,- file- formats,- and- specifications.

##- Core- Scripts- Reference

###- Main.jl

**Purpose**:- Primary- optimization- model- script

**Key- Configuration- Lines**:
-- **Line- 4**:- Solver- selection
- - ```julia
- - solver- =- "HiGHS"- - #- or- "Gurobi"
- - ```

-- **Lines- 22-25**:- Directory- configuration
- - ```julia
- - OptiPlant_directory- =- "C:/path/to/OptiPlant-master"
- - input_data_file- =- "Input_data_example"
- - input_sheet_name- =- "Data_base_case"
- - results_folder- =- "Results_base_case"
- - ```

-- **Line- 28**:- Scenario- sheet- reference- (if- creating- new- sheets)

**Dependencies**:- ImportData.jl,- ImportScenarios.jl

###- ImportData.jl

**Purpose**:- Data- import- functionality

**Functionality**:
-- Imports- techno-economic- parameters- from- Excel
-- Loads- renewable- energy- profiles
-- Processes- unit- characteristics- and- constraints

**Input- Requirements**:- 
-- Excel- files- in- BASE/Data/Inputs/
-- Profile- files- in- BASE/Data/Profiles/

###- ImportScenarios.jl

**Purpose**:- Scenario- configuration- management

**Functionality**:
-- Imports- scenario- definitions
-- Processes- operating- strategies
-- Handles- parameter- variations- for- sensitivity- analysis

**Input- Requirements**:- ScenariosToRun- and- Scenarios_definition- sheets

##- Data- Structure- Specifications

###- Excel- File- Structure

####- Input- Data- Workbook- Format

**Required- Sheets**:

1.- **Data_base_case**
- - - -- **Purpose**:- Master- unit- database
- - - -- **Columns**:- Unit- parameters,- technical- specifications,- economic- data
- - - -- **Key- Fields**:- Production- rates,- CapEx,- OpEx,- efficiency- factors
- - - -- **Special**:- Red- box- indicates- default- yearly- fuel- demands- (model- drivers)
- - - -- **Units**:- Various- (specified- in- each- column)

2.- **Selected_units**- 
- - - -- **Format**:- Binary- matrix- (1/0)
- - - -- **Rows**:- Available- units/technologies
- - - -- **Columns**:- Fuel- production- processes- (NH₃,- H₂,- MeOH,- etc.)
- - - -- **Purpose**:- Technology- selection- per- fuel- type
- - - -- **Default**:- Represents- "standard- case"- configuration

3.- **Scenarios_definition**
- - - -- **Purpose**:- Operating- strategy- parameters
- - - -- **Function**:- Intermediate- logic- layer
- - - -- **Usage**:- Sensitivity- analysis- configuration
- - - -- **Customization**:- User-defined- parameter- variations

4.- **ScenariosToRun**
- - - -- **Purpose**:- Scenario- execution- list- - 
- - - -- **Parameters**:- 
- - - - - -- Operating- strategy
- - - - - -- Location- (wind/solar- profiles)
- - - - - -- Year- (data- vintage)
- - - - - -- Produced- fuel- type
- - - - - -- Electrolyzer- technology
- - - -- **Critical**:- Names- must- match- exactly- across- sheets
- - - -- **Output**:- Determines- results- folder- naming

5.- **Sources**
- - - -- **Purpose**:- Data- references- and- citations
- - - -- **Content**:- Sources- for- Data_base_case- parameters
- - - -- **Maintenance**:- Update- when- modifying- input- data

####- Profile- Data- Workbook- Format

**File- Naming**:- Year-based- (e.g.,- `2019.xlsx`)

**Required- Sheets**:

1.- **Flux**
- - - -- **Content**:- Normalized- renewable- energy- profiles- (0-1)
- - - -- **Granularity**:- Hourly- data- for- full- year- (8760- rows)
- - - -- **Technologies**:- Multiple- wind- and- solar- technology- types
- - - -- **Locations**:- Various- geographic- locations
- - - -- **Sources**:- 
- - - - - -- Wind:- CorRES- tool
- - - - - -- Solar:- renewable.ninja- website

2.- **Price**
- - - -- **Content**:- Hourly- electricity- prices
- - - -- **Granularity**:- Hourly- data- for- full- year
- - - -- **Locations**:- Multiple- geographic- regions
- - - -- **Units**:- Currency- per- MWh
- - - -- **Coverage**:- Grid- buy- prices- by- location- and- time

###- Output- Data- Structure

####- CSV- File- Organization

**Folder- Structure**:
```
Results_[scenario_name]/
├──- Data- used/- - - - - - - - - - - #- Input- data- snapshots- (CSV)
├──- Hourly- results/- - - - - - #- Time-series- optimization- results- (CSV)
└──- Main- results/- - - - - - - - #- Summary- results- (CSV)
```

####- Output- Units- and- Formats

**Mass- Flows**:
-- **Non-electrical- units**:- t/h- (tonnes- per- hour)
-- **Hourly- results**:- kg/h- (values- ÷- 1000)
-- **Storage**:- t- (tonnes- total)

**Energy- Flows**:
-- **Electrical- units**:- MW- (megawatts)
-- **Hourly- results**:- kW- (values- ÷- 1000)
-- **Storage**:- MWh- (megawatt-hours)

**CSV- Format- Specifications**:
-- **Delimiter**:- Comma- (,)
-- **Decimal- separator**:- Dot- (.)
-- **Encoding**:- UTF-8
-- **Headers**:- First- row- contains- column- names

##- Solver- Integration

###- HiGHS- Solver

**Type**:- Open-source- linear- programming- solver

**Installation**:- 
```julia
add- HiGHS
```

**Usage**:- 
```julia
using- HiGHS
solver- =- "HiGHS"
```

**Characteristics**:
-- **Performance**:- Typically- <5- minutes- solve- time- on- personal- computer
-- **Reliability**:- Stable,- well-tested
-- **Licensing**:- Open-source,- no- restrictions
-- **Maintenance**:- Automatically- updated- with- Julia- packages

###- Gurobi- Solver

**Type**:- Commercial- linear- programming- solver

**Installation- Requirements**:
1.- Valid- Gurobi- license
2.- Gurobi- Optimizer- software- installation
3.- Julia- package:- `add- Gurobi`

**Performance**:- 
-- **Speed**:- Often- faster- than- HiGHS- for- large- problems
-- **Results**:- Identical- to- HiGHS- (same- optimal- solutions)
-- **Memory**:- Efficient- memory- usage- for- large-scale- problems

**License- Management**:
```bash
grbgetkey- <license-key>- - #- Command- Prompt
```

##- File- Format- Specifications

###- Excel- (.xlsx)- Requirements

**Compatibility**:- Microsoft- Excel- 2010+

**Sheet- Naming**:- 
-- **Case- sensitive**:- Exact- matches- required
-- **Special- characters**:- Avoid- in- sheet- names
-- **Length- limits**:- Keep- names- reasonable- (<31- characters)

**Data- Types**:
-- **Numeric**:- Use- consistent- decimal- notation
-- **Text**:- UTF-8- encoding- recommended
-- **Dates**:- Excel- date- format- if- applicable
-- **Boolean**:- Use- 1/0- for- Selected_units- sheet

###- CSV- Output- Specifications

**Format- Standards**:
-- **RFC- 4180- compliant**:- Standard- CSV- format
-- **Encoding**:- UTF-8- without- BOM
-- **Line- endings**:- Platform- appropriate- (CRLF/LF)
-- **Quoting**:- Fields- with- commas- automatically- quoted

**Numeric- Precision**:
-- **Default**:- 6- significant- figures
-- **Large- numbers**:- Scientific- notation- when- appropriate
-- **Consistency**:- Same- precision- across- related- outputs

##- Model- Parameters

###- Unit- Classification

**Non-electrical- Units**:
-- **Examples**:- Synthesis- reactors,- storage- tanks,- heat- exchangers
-- **Characteristics**:- Mass-based- flows- and- constraints
-- **Parameters**:- Production- rates- (t/h),- heat- requirements,- material- balances

**Electrical- Units**:
-- **Examples**:- Electrolyzers,- renewable- generators,- grid- connections
-- **Characteristics**:- Power-based- flows- and- constraints- - 
-- **Parameters**:- Capacity- (MW),- efficiency- (%),- electrical- consumption/production

###- Optimization- Constraints

**System-level**:
-- **Annual- fuel- demand**:- Must- be- satisfied- exactly
-- **Unit- capacity- limits**:- Lower- and- upper- bounds
-- **Ramping- constraints**:- Rate- of- change- limitations
-- **Storage- constraints**:- Inventory- balance- equations

**Operational**:
-- **Load- factors**:- Minimum/maximum- operating- points
-- **Efficiency- curves**:- Performance- vs.- load- relationships
-- **Maintenance**:- Planned- and- unplanned- availability
-- **Grid- interaction**:- Import/export- limitations

##- Performance- Specifications

###- Computational- Requirements

**Minimum- System**:
-- **RAM**:- 4GB- (8GB+- recommended- for- large- problems)
-- **Processor**:- Modern- multi-core- CPU
-- **Storage**:- 1GB- free- space- for- installation- +- results
-- **OS**:- Windows- 10+,- macOS- 10.14+,- Linux- (recent- distributions)

**Julia- Requirements**:
-- **Version**:- Julia- 1.6+- (1.8+- examples- shown- in- guide)
-- **Packages**:- JuMP,- solver- package,- data- handling- packages
-- **Environment**:- Activated- project- environment- recommended

###- Problem- Size- Limits

**Typical- Performance**:
-- **Solve- time**:- <5- minutes- for- standard- problems
-- **Variables**:- Thousands- to- tens- of- thousands
-- **Constraints**:- Similar- scale- to- variables
-- **Scenarios**:- Multiple- scenarios- in- single- run- supported

**Scaling- Factors**:
-- **Time- horizon**:- 8760- hours- (annual- optimization)
-- **Technologies**:- Dozens- of- unit- types- possible
-- **Locations**:- Multiple- locations- in- single- study
-- **Scenarios**:- Limited- by- available- memory- and- time

##- Integration- Points

###- Excel- Integration

**Import- Process**:
-- **XLSX.jl- package**:- Reads- Excel- files- directly
-- **Data- validation**:- Automatic- checks- for- required- sheets
-- **Error- handling**:- Informative- messages- for- missing/incorrect- data

**Export- Process**:
-- **CSV- generation**:- Structured- output- for- Excel- import
-- **Results- workbook**:- Pre-configured- Excel- file- with- macros
-- **Visualization**:- Pivot- Table- templates- for- analysis

###- Extensibility

**Adding- New- Technologies**:
1.- **Update- Data_base_case**:- Add- unit- parameters
2.- **Modify- Selected_units**:- Include- in- fuel- production- processes- - 
3.- **Update- Sources**:- Document- parameter- sources
4.- **Test- configuration**:- Verify- model- runs- correctly

**Adding- New- Locations**:
1.- **Create- profile- data**:- Wind/solar- profiles- for- location
2.- **Add- price- data**:- Electricity- costs- for- location
3.- **Update- scenarios**:- Include- location- in- ScenariosToRun
4.- **Validate- profiles**:- Ensure- data- quality- and- completeness

##- Error- Handling

###- Input- Validation

**Data- Consistency- Checks**:
-- **Sheet- existence**:- Required- sheets- in- Excel- files
-- **Data- types**:- Numeric- vs.- text- field- validation
-- **Range- checks**:- Reasonable- parameter- values
-- **Name- matching**:- Consistent- naming- across- sheets

**Profile- Validation**:
-- **Data- completeness**:- 8760- hours- of- data- required
-- **Value- ranges**:- Normalized- profiles- (0-1- for- renewable- resources)
-- **Temporal- consistency**:- Proper- time- series- structure

###- Runtime- Error- Management

**Solver- Errors**:
-- **Infeasibility**:- Model- constraints- cannot- be- satisfied
-- **Unbounded**:- Objective- function- has- no- optimal- bound
-- **Numerical- issues**:- Scaling- or- precision- problems

**File- System- Errors**:
-- **Path- validation**:- Directory- and- file- existence- checks
-- **Permission- issues**:- Read/write- access- verification
-- **Disk- space**:- Adequate- storage- for- results

##- Version- Compatibility

###- Julia- Ecosystem

**Core- Dependencies**:
-- **JuMP.jl**:- Optimization- modeling- language
-- **DataFrames.jl**:- Tabular- data- manipulation- - 
-- **CSV.jl**:- CSV- file- input/output
-- **XLSX.jl**:- Excel- file- reading

**Version- Stability**:
-- **LTS- Julia**:- Use- Long- Term- Support- versions- when- available
-- **Package- versions**:- Manifest.toml- locks- specific- versions
-- **Compatibility**:- Regular- testing- with- latest- package- versions

###- External- Software

**Excel- Compatibility**:
-- **Version- support**:- Excel- 2010- and- later
-- **Feature- requirements**:- Macros- enabled- for- Results- workbook
-- **Alternative- software**:- LibreOffice- Calc- compatibility- (limited)

**Operating- System**:
-- **Cross-platform**:- Julia- runs- on- Windows,- macOS,- Linux
-- **Path- conventions**:- Automatic- handling- of- OS-specific- paths
-- **Performance**:- Similar- across- platforms- for- optimization- tasks

##- Next- Steps

-- **[Examples](Examples.md)**- -- See- practical- applications- of- these- specifications
-- **[Usage- Guide](usage.md)**- -- Learn- how- to- use- the- file- structures
-- **[Installation](installation.md)**- -- Set- up- the- development- environment
