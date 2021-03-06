#=
  Contents: Script for constructing school size distribution.
  The intermediate data is copied from the raw Excel spreadsheet sourced from the ABS.
=#

################################################################################
# Functions

function longify(data::DataFrame)
    result = DataFrame(school_name=String[], year_level=Int[], count=Int[])
    n = size(data, 1)
    for j = 0:12
        colname = Symbol("year_$(j)")
        for i = 1:n
            nstudents = data[i, colname]
            ismissing(nstudents) && continue
            nstudents   = round(Int, nstudents)  # Accounts for part-time students
            school_name = data[i,  :school_name]
            push!(result, (school_name=school_name, year_level=j, count=nstudents))
        end
    end
    sort!(result, [:school_name, :year_level])
end

"Size bands of 10"
function avg_year_level_size(data::DataFrame)
    tmp = Dict{Tuple{Int, Int}, Int}()  # (lb, ub) => count
    for school in groupby(data, :school_name)
        n  = sum(school.count) / size(school, 1)
        lb = 10 * div(n, 10) + 1
        ub = lb + 9
        k  = (lb, ub)
        if !haskey(tmp, k)
            tmp[k] = 0
        end
        tmp[k] += 1
    end
    result = DataFrame(avg_year_level_size_lb=Int[], avg_year_level_size_ub=Int[], count=Int[])
    ntotal = 0
    for (k, v) in tmp
        push!(result, (avg_year_level_size_lb=k[1], avg_year_level_size_ub=k[2], count=v))
        ntotal += v
    end
    result[!, :proportion] = result.count ./ ntotal
    sort!(result, :avg_year_level_size_lb)
end



################################################################################
# Script

# Get data

#ACARA specific data
infile    = joinpath(cfg["input_datadir"], "ACARA_school_locations.tsv")
locations = DataFrame(CSV.File(infile; delim='\t'))
infile    = joinpath(cfg["input_datadir"], "ACARA_school_profile.tsv")
profile   = DataFrame(CSV.File(infile; delim='\t'))
locations = innerjoin(profile, locations, on="ACARA_SML_ID", makeunique=true)

if cfg["subpop_module"]
    infile = joinpath(cfg["input_datadir"], "SA2_subset.tsv")
    target_SA2_list = DataFrame(CSV.File(infile, delim='\t'))
    locations = locations[findall(in(target_SA2_list.SA2_code), locations.SA2_code),:]
end

#General data for year level splits
infile = joinpath(cfg["input_datadir"], "year_level_sizes_by_school.tsv")
data   = DataFrame(CSV.File(infile; delim='\t'))
data   = data[findall(in(locations.School_name),data.school_name),:]

# Convert to long form for Power BI. Columns: school_name, year_level, count
data    = longify(data)
outfile = joinpath(cfg["output_datadir"], "year_level_sizes_by_school_longform.tsv")
CSV.write(outfile, data; delim='\t')

# Construct result. Columns: avg_year_level_size_lb, avg_year_level_size_ub, count, proportion
primary = data[data[!, :year_level] .<= 6, :]
primary = avg_year_level_size(primary)
outfile = joinpath(cfg["output_datadir"], "avg_yearlevel_size_distribution_primary.tsv")
CSV.write(outfile, primary; delim='\t')

secondary = data[data[!, :year_level] .>= 7, :]
secondary = avg_year_level_size(secondary)
outfile   = joinpath(cfg["output_datadir"], "avg_yearlevel_size_distribution_secondary.tsv")
CSV.write(outfile, secondary; delim='\t')

#Output school locations and types
#locations[findall(x->x == "Primary",locations.School_type),:]

outfile = joinpath(cfg["output_datadir"], "schools_VIC_profile.tsv")
CSV.write(outfile, profile; delim='\t')
