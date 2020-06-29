#=
  Contents: Script for constructing population by age by SA2.
  The intermediate data is copied from the raw Excel spreadsheet sourced from the ABS.
=#

data_dir = "H:\\Documents\\data\\"
out_dir = "H:\\Documents\\data\\"
subpop_module = true
cd(data_dir)
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

infile = data_dir * "asgs_codes.tsv"
codes  = DataFrame(CSV.File(infile; delim='\t'))
infile = data_dir * "population_by_age_by_sa2.tsv"
data   = DataFrame(CSV.File(infile; delim='\t'))
data   = join(codes, data, on=:SA2_NAME_2016, kind=:left)
data   = data[data.STATE_NAME_2016 .== "Victoria", :]
show(size(data.STATE_NAME_2016))
# Format and write to disk
if subpop_module
    infile = data_dir * "SA2_subset.csv"
    target_SA2_list = Matrix(CSV.read(infile, type = Int64))
    data = data[findall(in(target_SA2_list),data.SA2_MAINCODE_2016),:]
end
data    = age_distribution(data)  # Columns: age, count
data    = data[data.count .> 0, :]
outfile = out_dir * "population_by_age_VIC.tsv"
CSV.write(outfile, data; delim='\t')
