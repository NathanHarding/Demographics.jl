#=
Contents: A script which takes a list of SA2/SA3/SA4 Regions and converts
to a list of SA2 to be used by population generation scripts
=#

using YAML
cfg = YAML.load(open("scripts\\config.yml"))
cd(cfg["output_datadir"])

using Pkg
Pkg.activate(".")

using CSV
using DataFrames

##########################################################################################
#Functions
function loop(subset_regions::DataFrame,all_regions::DataFrame)
	sa2_subset = Vector{Int}()
	for i=1:size(subset_regions,1)
		add_SA2!(subset_regions.SA_code[i],sa2_subset,all_regions)
	end
	sa2_subset
end

function add_SA2!(SA_code::Int,sa2_subset::Vector{Int},region_list::DataFrame)
	if 2e8 < SA_code < 3e8  #SA2
		append!(sa2_subset,SA_code)
	elseif 2e4 < SA_code < 3e4 #SA3
		append!(sa2_subset,region_list.SA2_MAINCODE_2016[findall(sa2_subset->floor(sa2_subset/10000)==SA_code,region_list.SA2_MAINCODE_2016),:])
	elseif 2e2 < SA_code < 3e2 #SA4
		append!(sa2_subset,region_list.SA2_MAINCODE_2016[findall(sa2_subset->floor(sa2_subset/1000000)==SA_code,region_list.SA2_MAINCODE_2016),:])
	else
		@info "invalid code" SA_code
	end
	sa2_subset
end

##########################################################################################
#Script

infile = cfg["input_datadir"] * "subset_regions.tsv"
subset_regions = DataFrame(CSV.File(infile;delim='\t'))
infile = cfg["input_datadir"] * "ASGS_codes.tsv"
all_regions = DataFrame(CSV.File(infile;delim='\t'))

if cfg["subpop_module"]
	sa2_subset = loop(subset_regions,all_regions)
else
	sa2_subset = all_regions.SA2_MAINCODE_2016[findall(x->x == "Victoria",all_regions.STATE_NAME_2016)] # only take SA2 codes from VIC region
end
sa2_subset = DataFrame(SA2_code = sa2_subset)

ofile =  "SA2_subset.tsv"
CSV.write(cfg["input_datadir"] *ofile,unique(sa2_subset);delim='\t')
CSV.write(cfg["output_datadir"] *ofile,unique(sa2_subset);delim='\t')

