#=
  Content: Map LGA to a set of SA2s via mesh blocks.

  Note: The resulting set of SA2s will cover the LGA with some overhang.
=#

using CSV
using DataFrames

# Input
indir   = "C:\\projects\\data\\dhhs\\demographics\\input"
mb2lga  = DataFrame(CSV.File(joinpath(indir, "MeshBlock_to_LGA_2016_VIC.csv"); delim=','))
mb2asgc = DataFrame(CSV.File(joinpath(indir, "MeshBlock_to_ASGC_2016_VIC.csv"); delim=','))

# Join and filter
data = leftjoin(mb2lga, mb2asgc, on=:MB_CODE_2016, makeunique=true)
select!(data, ["LGA_CODE_2016", "SA2_MAINCODE_2016", "LGA_NAME_2016", "SA2_NAME_2016"])
unique!(data)
sort!(data, ["LGA_NAME_2016", "SA2_NAME_2016"])

# Output
outfile = "C:\\projects\\data\\dhhs\\demographics\\output\\LGA_to_SA2.tsv"
CSV.write(outfile, data; delim='\t')
println("There are $(length(unique(data.SA2_NAME_2016))) SA2s over $(length(unique(data.LGA_NAME_2016))) LGAs, occupying $(size(data, 1)) rows.")
if length(unique(data.SA2_NAME_2016)) < size(data, 1)
    println("Some SA2s straddle at least 2 LGAs")
end