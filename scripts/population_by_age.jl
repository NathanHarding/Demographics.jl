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

# Get data

infile = joinpath(cfg["input_datadir"], "asgs_codes.tsv")
codes  = DataFrame(CSV.File(infile; delim='\t'))
infile = joinpath(cfg["input_datadir"], "population_by_age_by_sa2.tsv")
data   = DataFrame(CSV.File(infile; delim='\t'))
data   = leftjoin(codes, data, on=:SA2_NAME_2016)
data   = data[data.STATE_NAME_2016 .== "Victoria", :]

# Format and write to disk
if cfg["subpop_module"]
    infile = joinpath(cfg["input_datadir"], "SA2_subset.tsv")
    target_SA2_list = DataFrame(CSV.File(infile, delim='\t'))
    data = data[findall(in(target_SA2_list.SA2_code),data.SA2_MAINCODE_2016),:]
else
    target_SA2_list = DataFrame(SA2_code = data.SA2_MAINCODE_2016)
end
data_sp = sum.(eachrow(data[!,13:128]))
data_sp = DataFrame(SA2_code = data.SA2_MAINCODE_2016,cumsum_population = cumsum(data_sp))

outfile = joinpath(cfg["output_datadir"], "population_by_SA2.tsv")
CSV.write(outfile, data_sp; delim='\t')

result  = fill_age_data_frame(data,target_SA2_list.SA2_code)
outfile = joinpath(cfg["output_datadir"], "population_by_age_by_SA2.tsv")
CSV.write(outfile, result; delim='\t')