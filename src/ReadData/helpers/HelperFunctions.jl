"""
    locate_indexes(Data_sheet, key_terms::Dict, reduce_search_space::Bool=false)

Locates the positions of key terms in a data sheet and returns them as a named tuple.

This function searches for specified labels or terms in a given sheet (e.g., from Excel or CSV) 
and returns their coordinates as a `NamedTuple`. Optionally, the search can be restricted to 
the top-left 20x20 block to speed up the lookup in large sheets.

# Arguments
- `Data_sheet`: A 2D array (e.g., `Matrix` or `DataFrame`) representing the sheet to search.
- `key_terms`: A dictionary mapping symbolic labels to string terms to locate in the sheet.
- `reduce_search_space` (default: `false`): If `true`, limits the search to the top-left 20x20 block.

# Returns
- `NamedTuple`: Named tuple with symbols corresponding to `key_terms` keys. Each value is either:
    - A tuple `(row, column)` of the first occurrence of the term in the sheet.
    - `nothing` if the term is not found or `Data_sheet` is `nothing`.

"""

function locate_indexes(Data_sheet, key_terms::Dict, reduce_search_space::Bool=false)
    # Prepare a default output tuple with `nothing` values
    default_output = NamedTuple{Tuple(Symbol.(keys(key_terms)))}(fill(nothing, length(key_terms)))

    # Return default output if Data_sheet is nothing
    if isnothing(Data_sheet)
        return default_output
    end

    # Reduce search space
    if reduce_search_space == true && size(Data_sheet)[1] >= 20 && size(Data_sheet)[2] >= 20
        Data_sheet_search = Data_sheet[1:20, 1:20]
    else
        Data_sheet_search = Data_sheet
    end

    # Define local finder
    find_index(name) = findfirst(x -> x == name, Data_sheet_search)

    # Find all indexes based on key_terms
    indexes = Dict()
    for (label, term) in key_terms
        indexes[label] = find_index(term)
    end

    # Convert indexes Dict (with String keys) to NamedTuple with Symbol keys and return
    return NamedTuple{Tuple(Symbol.(keys(indexes)))}(values(indexes))
end

"""
    safe_extract_col(data, start_idx, col_idx; as_string::Bool=false)

Safely extracts a column from a 2D dataset, optionally converting values to strings.

This function extracts all rows from `start_idx` to the end in the specified column `col_idx`. 
If the column index is `nothing`, the function returns `nothing`. Values can optionally 
be converted to strings for uniform handling of mixed data types.

# Arguments
- `data`: A 2D array or table (e.g., `Matrix` or `DataFrame`) from which to extract the column.
- `start_idx`: Row index from which to start extraction.
- `col_idx`: Column index to extract. If `nothing`, the function returns `nothing`.
- `as_string` (optional, default: `false`): If `true`, converts all extracted values to strings.

# Returns
- `Vector`: Extracted values from the column, optionally converted to strings, or `nothing` if `col_idx` is `nothing`.

"""

function safe_extract_col(data, start_idx, col_idx; as_string::Bool=false)
    # Extract data from the specified column if it exists
    # If `as_string` is true, convert each element to a string if it is not already
    # If `col_idx` is nothing, return nothing
    if isnothing(col_idx)
        return nothing
    else
        values = data[start_idx:end, col_idx]
        return as_string ? [isa(x, String) ? x : string(x) for x in values] : values
    end
end

"""
    get_scenario_element_or_default(array, idx; default=nothing)

Safely retrieves an element from an array, returning a default value if the array is `nothing`.

This function is useful when extracting scenario-specific elements from a dataset 
that may be missing or undefined. It avoids errors caused by attempting to index `nothing`.

# Arguments
- `array`: The array or vector from which to extract the element.
- `idx`: The index of the element to retrieve.
- `default` (optional, default: `nothing`): Value to return if `array` is `nothing`.

# Returns
- The element at `array[idx]` if `array` is not `nothing`; otherwise, returns `default`.

"""

function get_scenario_element_or_default(array, idx; default=nothing)
    return isnothing(array) ? default : array[idx]
end

"""
    read_xlsx_sheet(workbook, sheetname, available_sheets; warn::Bool=false)

Reads a sheet from an Excel workbook safely, returning a matrix with missing values replaced by zeros.

This function checks whether the requested sheet exists in the list of available sheets 
before attempting to read it. If the sheet does not exist, it optionally issues a warning 
and returns `nothing`. All missing values in the sheet are replaced with `0`.

# Arguments
- `workbook`: Excel workbook object (e.g., from XLSX.jl) to read the sheet from.
- `sheetname`: Name of the sheet to read.
- `available_sheets`: Collection of valid sheet names in the workbook.
- `warn` (optional, default: `false`): If `true`, prints a warning when the sheet does not exist.

# Returns
- `Matrix`: Contents of the sheet with missing values replaced by `0`.
- `nothing`: If the sheet does not exist or `sheetname` is `nothing`.

"""


function read_xlsx_sheet(workbook, sheetname, available_sheets; warn::Bool=false)
    # Exit early if sheetname is invalid or missing
    if isnothing(sheetname) || !(sheetname in available_sheets)
        if warn
            @warn "The sheet $sheetname does not exist"
        end
        return nothing
    end

    # Only now read the file
    sheet = workbook[sheetname]
    data = sheet[:]
    return coalesce.(data, 0)  # Replace missing values with 0
end

"""
    extract_subset_profiles(data_profile, index)

Extracts a subset of profile data from a specified location in a profile matrix.

This function retrieves a horizontal slice of the profile matrix starting from the column 
given by `index[2] + 1` in the row specified by `index[1]`. It returns both the extracted 
subset and its length. If the profile data is missing, an error is logged and an empty subset is returned.

# Arguments
- `data_profile`: 2D array or matrix containing profile data (e.g., flux, price, or CO₂ profiles).
- `index`: Tuple `(row_index, column_index)` specifying the starting location for extraction.

# Returns
- `subset`: Vector containing the extracted profile subset.
- `length(subset)`: Integer giving the number of elements in the subset.

"""


function extract_subset_profiles(data_profile, index)
    if isnothing(data_profile)
        return [], 0
    end
    subset = data_profile[index[1], index[2] + 1:end]
    return subset, length(subset)
end

"""
    extract_subset_technoeco(data_technoeco, L1, index)

Extracts a column subset from techno-economic data starting at a specified row.

This function retrieves all entries in the column `index[2]` from row `L1` to the end 
of the `data_technoeco` matrix. It returns both the extracted subset and its length. 
If the data is missing, an error is logged and an empty subset is returned.

# Arguments
- `data_technoeco`: 2D array or matrix containing techno-economic data.
- `L1`: Starting row index for extraction.
- `index`: Tuple `(row_index, column_index)` specifying which column to extract.

# Returns
- `subset`: Vector containing the extracted data subset.
- `length(subset)`: Number of elements in the subset.


---

    extract_from_subsets(Subset_vector, target::String)

Identifies the indices of elements in a subset vector that match a target string.

This function searches a vector of subset labels and returns the positions 
of all elements equal to the specified `target`. If no elements match, 
it returns `(0, 0)` to indicate the absence of the subset.

# Arguments
- `Subset_vector`: Vector of strings representing subset labels.
- `target`: String specifying the subset label to search for.

# Returns
- `indices`: Vector of integer indices where `Subset_vector` equals `target`, or `0` if none.
- `nIndivSubset`: Number of matching elements, or `0` if none.

"""


function extract_subset_technoeco(data_technoeco, L1, index)
    if isnothing(data_technoeco) 
        @error "Techno-economic data file missing or named incorrectly"
        return [], 0
    end
    subset = data_technoeco[L1:end, index[2]]
    return subset, length(subset)
end

#Function to extract individual subsets from the subset vectors and put a zero value if the subset do not exists

function extract_from_subsets(Subset_vector, target::String)
    indices = Int[]
    for (i, val) in enumerate(Subset_vector)
        if val == target
            push!(indices, i)
        end
    end
    nIndivSubset = length(indices)
    return nIndivSubset == 0 ? (0, 0) : (indices, nIndivSubset)
end


"""
    get_data_from_table(data, parameter_to_find, column_header_list, L1, C0;
                        as_string::Bool=false, warn::Bool=false)

Safely retrieves a column of data corresponding to a specified parameter from a table.

This function searches `column_header_list` for `parameter_to_find` and extracts the 
corresponding column from `data`, starting at row `L1` and offset by `C0`. If the 
parameter is not found, it returns a zero-filled vector (or `nothing` if `as_string=true`) 
and optionally issues a warning.

# Arguments
- `data`: 2D array or matrix containing the table data.
- `parameter_to_find`: Name of the parameter/column to extract.
- `column_header_list`: Vector of column headers in `data`.
- `L1`: Row index from which to start extraction.
- `C0`: Column offset for indexing the table.
- `as_string` (optional, default: `false`): If `true`, converts all extracted values to strings.
- `warn` (optional, default: `false`): If `true`, prints a warning when the parameter is missing.

# Returns
- `Vector`: Column of extracted values (numeric or string), or zero-filled/nothing if the parameter is missing.

"""
function get_data_from_table(
    data, 
    parameter_to_find, 
    column_header_list, 
    L1, 
    C0; 
    offset::Int64 = 0,
    as_string::Bool=false, 
    warn::Bool=false
)
    # Find the index of the column that matches the parameter
    col_idx = findfirst(x -> x == parameter_to_find, column_header_list)
    
    # If the parameter is not found, handle accordingly
    if isnothing(col_idx)
        num_rows = size(data, 1) - L1 + 1
        if warn
            @warn("Missing data: $parameter_to_find")
        end
        return as_string ? nothing : zeros(num_rows)
    else
        # Extract the values from the specified rows and column
        values = data[L1:end, C0 + col_idx + offset]
        # Convert to string if requested
        return as_string ? [isa(x, String) ? x : string(x) for x in values] : values
    end
end


"""
    matrix_to_dataframe(mat::AbstractMatrix, prefix::String = "col")

Converts a numeric matrix into a `DataFrame` with time steps as rows and named columns.

This function transposes the input matrix so that each row represents a time step and 
each column represents a profile. Column names are automatically generated using the 
specified `prefix` followed by an index (e.g., `col_1`, `col_2`, ...). A `time` column 
is added as the first column, representing the row indices.

# Arguments
- `mat`: Numeric matrix of size `(profiles, time_steps)` or `(rows, columns)`.
- `prefix` (optional, default: `"col"`): String prefix for automatically generated column names.

# Returns
- `DataFrame`: A `DataFrame` with columns `:time` followed by profile columns with names like `prefix_1, prefix_2, ...`.

"""


function matrix_to_dataframe(mat::AbstractMatrix, prefix::String = "col")
    # Transpose so rows = time steps, columns = profiles
    mat_T = transpose(mat)

    # Generate column names like col_1, col_2, ...
    col_names = [Symbol(prefix * "_" * string(i)) for i in 1:size(mat_T, 2)]

    # Create the DataFrame
    df = DataFrame(mat_T, col_names)

    # Add time column
    df.time = 1:size(mat_T, 1)

    # Move time to the front
    select!(df, [:time; col_names...])
    return df
end

