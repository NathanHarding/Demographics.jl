#=
  Contents: Script for constructing population by age by SA2.
  The intermediate data is copied from the raw Excel spreadsheet sourced from the ABS.
=#

################################################################################
# Functions

function fill_age_data_frame(data::DataFrame,SA2_list::Vector)
    for col in names(data[:, [1;13:128]])  #dirty fix before report - needs permanent solution
        data[ismissing.(data[!,col]), col] .= 0
    end
    row_values = disallowmissing(Matrix(data[:,[1;13:128]]))
    result = DataFrame(age = Vector(0:115))
    i = 1
    for SA2 in SA2_list
        values = vec(row_values[findall(x->x == SA2,row_values[:,1]),2:end])   #First column contains SA2 code
        if sum(values)!= 0
             values = values./sum(values) #Normalise but avoid Nans
        end
        result[!,Symbol(SA2)] = values
        end
    result
end

################################################################################
# Script

# Get SA2/3/4 codes in the target population
target_SA2_codes = DataFrame(CSV.File(joinpath(cfg["input_datadir"], "SA2_subset.tsv"), delim='\t'))
allcodes = DataFrame(CSV.File(joinpath(cfg["input_datadir"], "asgs_codes.tsv"); delim='\t'))  # All SA2s
codes    = leftjoin(target_SA2_codes, allcodes, on= :SA2_code => :SA2_MAINCODE_2016)          # Target SA2s only
rename!(codes, :SA2_code => :SA2_MAINCODE_2016)

# Get population count by age by SA2 for target SA2s
infile = joinpath(cfg["input_datadir"], "population_by_age_by_sa2.tsv")
data   = DataFrame(CSV.File(infile; delim='\t'))   # All SA2s
data[!,  :name2] = lowercase.(data.SA2_NAME_2016)  # Join on lowercase names as there are some mismatches otherwise
codes[!, :name2] = lowercase.(codes.SA2_NAME_2016)
data   = leftjoin(codes, data, on=:name2, makeunique=true)  # target SA2s only
select!(data, Not([:name2, :SA2_NAME_2016_1]))

# Construct population by SA2 and write to disk
data_sp = sum.(eachrow(data[!, 13:end]))
data_sp = DataFrame(SA2_code = data.SA2_MAINCODE_2016, cumsum_population = cumsum(data_sp))
outfile = joinpath(cfg["output_datadir"], "population_by_SA2.tsv")
CSV.write(outfile, data_sp; delim='\t')

# Construct age distribution by SA2. Each column is a categorical distribution over ages for a SA2.
result  = fill_age_data_frame(data, target_SA2_codes.SA2_code)
outfile = joinpath(cfg["output_datadir"], "population_by_age_by_SA2.tsv")
CSV.write(outfile, result; delim='\t')