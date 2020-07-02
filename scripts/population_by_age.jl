#=
  Contents: Script for constructing population by age by SA2.
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

function age_distribution(data::DataFrame)
    result   = DataFrame(age=Int[], count=Int[])
    colidx1  = findfirst(==("0"), names(data))
    colidx2  = size(data, 2)
    colnames = names(data)
    ntotal   = 0
    for j = colidx1:colidx2
        colname = string(colnames[j])
        coldata = data[!, j]
        age = parse(Int, colname)
        n   = sum(x for x in coldata if !ismissing(x))  # The last row has missing data
        push!(result, (age=age, count=n))
        ntotal += n
    end
    result[!, :proportion] = result.count ./ ntotal
    result
end

################################################################################
# Script

# Get data

infile = cfg["input_datadir"] * "asgs_codes.tsv"
codes  = DataFrame(CSV.File(infile; delim='\t'))
infile = cfg["input_datadir"] * "population_by_age_by_sa2.tsv"
data   = DataFrame(CSV.File(infile; delim='\t'))
data   = join(codes, data, on=:SA2_NAME_2016, kind=:left)
data   = data[data.STATE_NAME_2016 .== "Victoria", :]
# Format and write to disk
if cfg["subpop_module"]
    infile = cfg["input_datadir"] * "SA2_subset.csv"
    target_SA2_list = DataFrame(CSV.File(infile, delim='\t'))
    data = data[findall(in(target_SA2_list.SA2_code),data.SA2_MAINCODE_2016),:]
end
data    = age_distribution(data)  # Columns: age, count
data    = data[data.count .> 0, :]
outfile = cfg["output_datadir"] * "population_by_age.tsv"
CSV.write(outfile, data; delim='\t')
