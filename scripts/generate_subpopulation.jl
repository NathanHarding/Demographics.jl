#=
Contents: A script which takes a list of SA2/SA3/SA4 Regions and converts
to a list of SA2 to be used by population generation scripts
=#

data_dir = "H:\\Documents\\data\\"
out_dir = "H:\\Documents\\data\\"
cd(data_dir)

using Pkg
Pkg.activate(".")

using CSV
using DataFrames

##########################################################################################
#Functions
function loop(subset_regions::DataFrame,all_regions::DataFrame)
	sa2_subset = Vector{Int}()
	idx = 1
	for i=1:size(subset_regions,1)
		add_SA2!(subset_regions.Code[i],subset_regions.SA_type[i],sa2_subset,all_regions)
	end
	sa2_subset
end

function add_SA2!(SA_code::Int,SA_type::String,sa2_subset::Vector{Int},region_list::DataFrame)
	if SA_type == "SA2"
		append!(sa2_subset,SA_code)
	end
	if SA_type == "SA3"
		append!(sa2_subset,region_list.SA2_MAINCODE_2016[findall(sa2_subset->floor(sa2_subset/10000)==SA_code,region_list.SA2_MAINCODE_2016),:])
	end
	if SA_type == "SA4"
		append!(sa2_subset,region_list.SA2_MAINCODE_2016[findall(sa2_subset->floor(sa2_subset/1000000)==SA_code,region_list.SA2_MAINCODE_2016),:])
	end
	sa2_subset
end

##########################################################################################
#Script

infile = data_dir * "subset_regions.tsv"
subset_regions = DataFrame(CSV.read(infile;delim='\t'))
infile = data_dir * "ASGS_codes.tsv"
all_regions = DataFrame(CSV.read(infile;delim='\t'))

sa2_subset = loop(subset_regions,all_regions)
sa2_subset = DataFrame(SA2_code = sa2_subset)

ofile = data_dir * "SA2_subset.csv"
CSV.write(ofile,unique(sa2_subset))

