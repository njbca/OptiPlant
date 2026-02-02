# Convert capacity units
function scale_mass_power_energy_units(
    value::Float64,
    label::String;
    force_unit_prefix::Union{Nothing, String}=nothing
)
    # Scaling rules: thresholds, units
    scaling = Dict(
        # Mass
        "kg"  => ([1e3, 1e6], ["kg", "t", "kt"]),
        "t"   => ([1e3, 1e6], ["t", "kt"]),
        "kt"  => ([Inf, Inf], ["kt"]),
        # Power
        "kW"  => ([1e3, 1e6], ["kW", "MW", "GW"]),
        "MW"  => ([1e3, 1e6], ["MW", "GW"]),
        "GW"  => ([Inf, Inf], ["GW"]),
        # Energy
        "kWh" => ([1e3, 1e6], ["kWh", "MWh", "GWh"]),
        "MWh" => ([1e3, 1e6], ["MWh", "GWh"]),
        "GWh" => ([Inf, Inf], ["GWh"]),
        # Energy joules
        "kJ" => ([1e3, 1e6], ["kJ", "MJ", "GJ"]),
        "MJ" => ([1e3, 1e6], ["MJ", "GJ"]),
        "GJ" => ([Inf, Inf], ["GJ"])
    )

    # Detect prefix from label
    keylist = sort(collect(keys(scaling)), by=length, rev=true)
    idx = findfirst(p -> startswith(label, p), keylist)

    if isnothing(idx)
        return value, label  # no match → unchanged
    end
    prefix = keylist[idx]
    thresholds, units = scaling[prefix]
    suffix = replace(label, prefix => "")

    # Forced scaling
    if ! isnothing(force_unit_prefix)
        # Category mapping
        unit_categories = Dict(
            "kg" => "mass", "t" => "mass", "kt" => "mass",
            "kW" => "power", "MW" => "power", "GW" => "power",
            "kWh" => "energy", "MWh" => "energy", "GWh" => "energy",
            "kJ" => "energyJ", "MJ" => "energyJ", "GJ" => "energyJ"
        )
        # Base factors relative to smallest unit
        base_factors = Dict(
            "kg" => 1.0, "t" => 1e3, "kt" => 1e6,
            "kW" => 1.0, "MW" => 1e3, "GW" => 1e6,
            "kWh" => 1.0, "MWh" => 1e3, "GWh" => 1e6,
            "kJ" => 1.0, "MJ" => 1e3, "GJ" => 1e6
        )

        allowed_prefixes = split(force_unit_prefix, r"\s+or\s+")
        category = unit_categories[prefix]
        target = only(filter(p -> unit_categories[p] == category, allowed_prefixes))

        factor = base_factors[prefix] / base_factors[target]
        return value * factor, target * suffix
    end

    # Auto-scaling
    if value >= thresholds[2]
        return value / thresholds[2], units[end] * suffix
    elseif value >= thresholds[1]
        return value / thresholds[1], units[2] * suffix
    else
        return value, units[1] * suffix
    end
end


function scale_cost_units(
    value::Float64,
    currency_multiplier::Float64;
    force_unit::Union{Nothing, String}=nothing
)
    scaled_value = value * currency_multiplier

    # Handle forced unit scaling
    if !isnothing(force_unit)
        unit_factors = Dict(
            ""  => 1.0,
            "k" => 1e-3,
            "M" => 1e-6,
            "B" => 1e-9
        )

        if !haskey(unit_factors, force_unit)
            error("Unsupported forced unit: $force_unit. Use \"\", \"k\", \"M\" or \"B\".")
        end

        return scaled_value * unit_factors[force_unit]
    end

    # Automatic scaling
    if abs(scaled_value) < 1e3
        return scaled_value
    elseif abs(scaled_value) < 1e6
        return scaled_value / 1e3
    else
        return scaled_value / 1e6
    end
end

#=
function simplify_unit_fraction(unit_str::String)
    prefixes = Dict("" => 0, "k" => 3, "M" => 6, "G" => 9)

    # Extract prefix and base unit
    function split_unit(u)
        m = match(r"^(k|M|G|)?(.*)$", strip(u))
        return (isnothing(m.captures[1]) ? "" : m.captures[1], m.captures[2])
    end

    # Split numerator and denominator
    num_str, den_str = split(unit_str, "/", limit=2)
    den_unit, den_label = match(r"^(\S+)(.*)$", strip(den_str)).captures

    # Break into prefix + base
    num_p, num_base = split_unit(num_str)
    print(split_unit(num_str))
    den_p, den_base = split_unit(den_unit)
    print(split_unit(den_unit))

    # Net scale shift
    net_exp = prefixes[num_p] - prefixes[den_p]

    # Apply scale shift
    if net_exp > 0
        new_num_p = first(k for (k,v) in prefixes if v == net_exp)
        new_den_p = ""
    elseif net_exp < 0
        new_num_p = ""
        new_den_p = first(k for (k,v) in prefixes if v == -net_exp)
    else
        new_num_p, new_den_p = "", ""
    end

    return "$(new_num_p)$(num_base)/$(new_den_p)$(den_base)$(den_label)"
end
=#