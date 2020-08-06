#=
  Content: Map each SA2 to a health service cluster.
  Note:    The mapping is approximate. See notes to scripts/lga_to_cluster.jl.
=#

using CSV
using DataFrames

# Step 1: Run scripts/lga_to_sa2.jl

# Step 2: Run scripts/lga_to_cluster.jl

# Step 3: Join the results of steps 1 and 2
indir          = "C:\\projects\\data\\dhhs\\demographics\\output"
sa2_to_lga     = DataFrame(CSV.File(joinpath(indir, "LGA_to_SA2.tsv"); delim='\t'))
lga_to_cluster = DataFrame(CSV.File(joinpath(indir, "LGA_to_cluster.tsv"); delim='\t'))

# Rename some LGAs to match the sa2_to_lga table
lga_to_cluster[lga_to_cluster.lga_name .== "Kingston (C)", :lga_name] = "Kingston (C) (Vic.)"
lga_to_cluster[lga_to_cluster.lga_name .== "Latrobe (C)", :lga_name] = "Latrobe (C) (Vic.)"
lga_to_cluster[lga_to_cluster.lga_name .== "Wodonga (RC)", :lga_name] = "Wodonga (C)"

# Result
result  = leftjoin(lga_to_cluster, sa2_to_lga, on="lga_name" => "LGA_NAME_2016")
outfile = "C:\\projects\\data\\dhhs\\demographics\\output\\sa2_to_cluster.tsv"
CSV.write(outfile, result; delim='\t')