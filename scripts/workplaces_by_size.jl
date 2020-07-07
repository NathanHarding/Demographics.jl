#=
  Contents: Script for converting intermediate work place data to consumable data.
  The intermediate data is copied from the raw Excel spreadsheet sourced from the ABS.
=#


using YAML
cfg = YAML.load(open("scripts\\config.yml"))
cd(cfg["output_datadir"])
using Pkg
Pkg.activate(".")

using CSV
using DataFrames

################################################################################
# Functions

function count_employees(data, colnames)
    result = Dict{Tuple{Int, Int}, Int}()  # nemployees_lb => count
    for colname in colnames
        s  = string(colname)
        i1 = findfirst(==('_'), s) + 1
        i2 = findfirst("to", s)
        i2 = isnothing(i2) ? findfirst("plus", s) : i2
        i2 = isnothing(i2) ? i1 : i2[1] - 1
        lb = parse(Int, s[i1:i2])
        if occursin("to", s)
            i1 = findfirst("to", s)[end] + 1
            ub = parse(Int, s[i1:end])
        elseif occursin("plus", s)
            ub = 5_000
        else
            ub = 0
        end
        result[(lb, ub)] = sum(data[!, colname])
    end
    result
end

function counts_to_table(grp2count::Dict)
    result = DataFrame(nemployees_lb=Int[], nemployees_ub=Int[], count=Int[])
    ntotal = 0
    for (lb_ub, n_businesses) in grp2count
        d = (nemployees_lb=lb_ub[1], nemployees_ub=lb_ub[2], count=n_businesses)
        push!(result, d)
        ntotal += n_businesses
    end
    result[!, :proportion] = result.count ./ ntotal
    sort!(result, :nemployees_lb)
    result
end

################################################################################
# Script

# Get data
infile = cfg["input_datadir"] * "workplace_size_by_industry_by_SA2.tsv"
data   = DataFrame(CSV.File(infile; delim='\t',types = Dict(5=>Int64,6=>Int64,7=>Int64,8=>Int64,9=>Int64)))

if cfg["subpop_module"]
    infile = cfg["input_datadir"] * "SA2_subset.tsv"
    target_SA2_list = DataFrame(CSV.File(infile, delim='\t'))
    data = data[findall(in(target_SA2_list.SA2_code),data.SA2_code),:]
end
if !cfg["subpop_module"]
    data.SA2_code = [ismissing(x) ? missing : string(x) for x in data.SA2_code]
    keep = [!ismissing(x) && x[1] == '2' for x in data.SA2_code]
    data = data[keep, :]
    keep = nothing
end

# Take data from selected regions


# Count groups
colnames  = [:nemployees_0, :nemployees_1to4, :nemployees_5to19, :nemployees_20to199, :nemployees_200plus]
grp2count = count_employees(data, colnames)

# Construct result and write to disk
data    = counts_to_table(grp2count)
outfile = cfg["output_datadir"] * "workplace_by_size_VIC.tsv"
CSV.write(outfile, data; delim='\t')
