module saveload

export save, load

using Dates
#using JSON
using JSON3

using ..persons
using ..contacts.households
using ..contacts.workplaces
using ..contacts.social_networks
using ..contacts.community_networks


JSON3.StructTypes.StructType(::Type{Person{A, S}}) where {A, S} = JSON3.StructTypes.Mutable()
JSON3.StructTypes.StructType(::Type{households.Household})      = JSON3.StructTypes.Mutable()

Person{A, S}() where {A, S} = Person(0, Date(1900, 1, 1), 'o', 'x', nothing, 0, nothing, nothing, 0, 0)
households.Household() = households.Household(0, 0, Int[], Int[])


function save(people::Vector{Person{A, S}}, filename::String) where {A, S}
    d = Dict{String, Any}()
    d["people"]            = people
    d["households"]        = households._households
    d["workplaces"]        = workplaces._workplaces
    d["communitycontacts"] = community_networks.communitycontacts
    d["socialcontacts"]    = social_networks.socialcontacts
    #s = JSON.json(d)
    s = JSON3.write(d)
    write(filename, s)
end

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

end