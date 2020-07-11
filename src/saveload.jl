module saveload

export save, load

using CSV
using DataFrames
using Dates
using JSON  # For parsing string(vector) into vector. E.g., JSON.parse("[1,2,3]") == [1,2,3]
using Logging

using ..persons
using ..contacts
using ..contacts.households
using ..contacts.workplaces
using ..contacts.social_networks
using ..contacts.community_networks

function save(people::Vector{Person{A, S}}, outdir::String) where {A, S}
    @info "$(now()) Writing params to disk"
    table = [(name=k, value=v) for (k, v) in contacts._params]
    CSV.write(joinpath(outdir, "params.tsv"), table; delim='\t')

    @info "$(now()) Writing people to disk"
    table = tabulate_people(people)
    CSV.write(joinpath(outdir, "people.tsv"), table; delim='\t')

    @info "$(now()) Writing households to disk"
    table = tabulate_households(households._households)
    CSV.write(joinpath(outdir, "households.tsv"), table; delim='\t')

    @info "$(now()) Writing work places to disk"
    table = tabulate_workplaces(workplaces._workplaces)
    CSV.write(joinpath(outdir, "workplaces.tsv"), table; delim='\t')

    @info "$(now()) Writing community contacts to disk"
    table = tabulate_community_contacts(community_networks.communitycontacts)
    CSV.write(joinpath(outdir, "communitycontacts.tsv"), table; delim='\t')

    @info "$(now()) Writing social networks to disk"
    table = DataFrame(socialcontacts = social_networks.socialcontacts)
    CSV.write(joinpath(outdir, "socialcontacts.tsv"), table; delim='\t')
end

function load(datadir::String)
    !isdir(datadir) && error("Directory does not exist: $(datadir)")
    load_params!(joinpath(datadir, "params.tsv"))
    load_households!(joinpath(datadir, "households.tsv"))
    load_workplaces!(joinpath(datadir, "workplaces.tsv"))
    load_communitycontacts!(joinpath(datadir, "communitycontacts.tsv"))
    load_socialcontacts!(joinpath(datadir, "socialcontacts.tsv"))
    load_people(joinpath(datadir, "people.tsv"))  # Returns Vector{Person}
end

###############################################################################
# Vector of objects to table

function tabulate_people(people::Vector{Person{Int, Nothing}})
    n      = length(people)
    result = DataFrame(id=fill(0, n), birthdate=Vector{Date}(undef, n), sex=fill('o', n), address=fill(0, n), i_household=fill(0, n),
                       school=missings(String, n), i_workplace=missings(Int, n), j_workplace=missings(Int, n),
                       i_community=fill(0, n), i_social=fill(0, n))
    for (i, person) in enumerate(people)
        person_to_row!(result, i, person)
    end
    result
end

function tabulate_households(hholds)
    n      = length(hholds)
    result = DataFrame(max_nadults=fill(0, n), max_nchildren=fill(0, n), adults=missings(String, n), children=missings(String, n))
    for (i, hhold) in enumerate(hholds)
        household_to_row!(result, i, hhold)
    end
    result
end

function tabulate_workplaces(wplaces)
    n      = length(wplaces)
    result = DataFrame(workplace=missings(String, n))
    for (i, wp) in enumerate(wplaces)
        result[i, :workplace] = string(wp)
    end
    result
end

"Result: A long table with 2 columns: address, contactid."
function tabulate_community_contacts(address2contacts::Dict{Int, Vector{Int}})
    n      = sum(length(contactids) for (address, contactids) in address2contacts)
    i      = 0
    result = DataFrame(address=fill(0, n), contactid=fill(0, n))
    for (address, contactids) in address2contacts
        for contactid in contactids
            i += 1
            result[i, :address]   = address
            isempty(contactids) && continue
            result[i, :contactid] = contactid
        end
    end
    result
end

###############################################################################
# Object to row

"Store person in result[i, :]"
function person_to_row!(result::DataFrame, i::Int, person::Person{Int, Nothing})
    # Demographic variables
    result[i, :id]        = person.id
    result[i, :birthdate] = person.birthdate
    result[i, :sex]       = person.sex
    result[i, :address]   = person.address

    # Contacts
    result[i, :i_household] = person.i_household
    result[i, :i_community] = person.i_community
    result[i, :i_social]    = person.i_social
    school = person.school
    if !isnothing(school)
        result[i, :school] = string(school)
    end   
    ij = person.ij_workplace
    if !isnothing(ij)
        result[i, :i_workplace] = ij[1]
        result[i, :j_workplace] = ij[2]
    end
    result
end

function household_to_row!(result, i, hhold)
    result[i, :max_nadults]   = hhold.max_nadults
    result[i, :max_nchildren] = hhold.max_nchildren
    result[i, :adults]        = isempty(hhold.adults)   ? missing : string(hhold.adults)
    result[i, :children]      = isempty(hhold.children) ? missing : string(hhold.children)
end

################################################################################
# Load

function load_params!(filename::String)
    @info "$(now()) Loading params"
    data = DataFrame(CSV.File(filename; delim='\t'))
    dest = contacts._params
    for row in eachrow(data)
        dest[Symbol(row[:name])] = Float64(row[:value])
    end
end

function load_households!(filename::String)
    @info "$(now()) Loading households"
    data = DataFrame(CSV.File(filename; delim='\t'))
    dest = households._households
    empty!(dest)
    for row in eachrow(data)
        adults   = unstringify_vector(row[:adults], Int)
        children = unstringify_vector(row[:children], Int)
        hhold    = households.Household(row[:max_nadults], row[:max_nchildren], adults, children)
        push!(dest, hhold)
    end
end

function load_workplaces!(filename::String)
    @info "$(now()) Loading work places"
    data = DataFrame(CSV.File(filename; delim='\t'))
    dest = workplaces._workplaces
    empty!(dest)
    for row in eachrow(data)
        workplace = unstringify_vector(row[:workplace], Int)
        push!(dest, workplace)
    end
end

function load_communitycontacts!(filename::String)
    @info "$(now()) Loading community contacts"
    data = DataFrame(CSV.File(filename; delim='\t'))
    dest = community_networks.communitycontacts
    empty!(dest)
    for subdata in groupby(data, :address)
        address = subdata[1, :address]
        dest[address] = [x for x in subdata.contactid]
    end
end

function load_socialcontacts!(filename::String)
    @info "$(now()) Loading social contacts"
    data = DataFrame(CSV.File(filename; delim='\t'))
    dest = social_networks.socialcontacts
    empty!(dest)
    for row in eachrow(data)
        push!(dest, row[:socialcontacts])
    end
end

function load_people(filename::String)
    @info "$(now()) Loading people"
    data    = DataFrame(CSV.File(filename; delim='\t'))
    npeople = size(data, 1)
    people  = Vector{Person{Int, Nothing}}(undef, npeople)
    i = 0
    for row in eachrow(data)
        i += 1
        school       = ismissing(row[:school]) ? nothing : unstringify_vector(row[:school], Int)
        ij_workplace = ismissing(row[:i_workplace]) ? nothing : (row[:i_workplace], row[:j_workplace])
        people[i]    = Person{Int, Nothing}(row[:id], row[:birthdate], row[:sex][1], row[:address], nothing,
                                            row[:i_household], school, ij_workplace, row[:i_community], row[:i_social])
    end
    people
end

################################################################################
# Utils

function unstringify_vector(s::String, T::DataType)
    s == "missing"    && return T[]
    occursin("[]", s) && return T[]  # s is a stringified empty vector
    v = JSON.parse(s)  # Vector{Any}
    convert(Vector{T}, v)
end

unstringify_vector(s::Missing, T::DataType) = T[]

end