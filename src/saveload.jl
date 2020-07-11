module saveload

export save, load

using CSV
using DataFrames
using Dates
using Logging

using ..persons
using ..contacts.households
using ..contacts.workplaces
using ..contacts.social_networks
using ..contacts.community_networks

function save(people::Vector{Person{A, S}}, outdir::String) where {A, S}
    @info "$(now()) Converting people to table"
    table = tabulate_people(people)
    @info "$(now()) Writing people to disk"
    CSV.write(joinpath(outdir, "people.tsv"), table; delim='\t')

    @info "$(now()) Converting households to table"
    table = tabulate_households(households._households)
    CSV.write(joinpath(outdir, "households.tsv"), table; delim='\t')

    @info "$(now()) Converting work places to table"
    table = tabulate_workplaces(workplaces._workplaces)
    CSV.write(joinpath(outdir, "workplaces.tsv"), table; delim='\t')

    @info "$(now()) Converting community contacts to table"
    table = tabulate_community_contacts(community_networks.communitycontacts)
    CSV.write(joinpath(outdir, "communitycontacts.tsv"), table; delim='\t')

    @info "$(now()) Converting social networks to table"
    table = DataFrame(socialcontacts = social_networks.socialcontacts)
    CSV.write(joinpath(outdir, "socialcontacts.tsv"), table; delim='\t')
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
    result[i, :adults]        = string(hhold.adults)
    result[i, :children]      = string(hhold.children)
end

################################################################################

#=
function load(filename::String)
    s = String(read(filename))
    d = JSON3.read(s)
    #d = JSON.parse(s)
    load_households!(d["households"])
    load_workplaces!(d["workplaces"])
    load_communitycontacts!(d["communitycontacts"])
    load_socialcontacts!(d["socialcontacts"])
    construct_people(d["people"])
end

function load_households!(v)
    dest = households._households
    empty!(dest)
    for d in v
        hh = households.Household(d["max_nadults"], d["max_nchildren"], d["adults"], d["children"])
        push!(dest, hh)
    end
end

function load_workplaces!(v)
    dest = workplaces._workplaces
    empty!(dest)
    for v2 in v
        push!(dest, v2)
    end
end

function load_communitycontacts!(v)
    dest = community_networks.communitycontacts
    empty!(dest)
    for x in v
        push!(dest, x)
    end
end

function load_socialcontacts!(v)
    dest = social_networks.socialcontacts
    empty!(dest)
    for x in v
        push!(dest, x)
    end
end

function construct_people(v)
    npeople = size(v, 1)
    people  = Vector{Person{String, Nothing}}(undef, npeople)
    for i = 1:npeople
        people[i] = Person{String, Nothing}(v[i])
    end
    people
end

function Person{A, S}(d::T) where {A, S, T <: Dict}
    id           = d["id"]
    birthdate    = Date(d["birthdate"])
    sex          = d["sex"][1]  # Char
    address      = d["address"]
    state        = nothing
    i_household  = d["i_household"]
    school       = isnothing(d["school"]) ? nothing : [x for x in d["school"]]
    ij_workplace = isnothing(d["ij_workplace"]) ? nothing : Tuple(d["ij_workplace"])
    i_community  = d["i_community"]
    i_social     = d["i_social"]
    Person{A, S}(id, birthdate, sex, address, state, i_household, school, ij_workplace, i_community, i_social)
end
=#

end