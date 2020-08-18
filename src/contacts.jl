module contacts

export populate_contacts!, get_contactlist, getcontact

using Dates
using Logging
using DataFrames

using ..utils
using ..persons

include("contact_networks/households.jl")          # Depends on: utils, persons
include("contact_networks/schools.jl")             # Depends on: utils, persons
include("contact_networks/workplaces.jl")          # Depends on: persons
include("contact_networks/social_networks.jl")     # Independent
include("contact_networks/community_networks.jl")  # Independent

using .households
using .schools
using .workplaces
using .social_networks
using .community_networks

const contactids = fill(0, 1000)  # Buffer for a mutable contact list
const _params = Dict{Symbol, Float64}()  # Used for saving/loading to/from disk

getcontact(i) = contactids[i]

"""
We currently assume that teachers and students live in the same SA2 as their school.
We can relax this constraint by moving and/or swapping teachers/students between schools with prob=p.
"""
function populate_contacts!(people::Vector{Person{A, S}}, params, indata, dt::Date) where {A, S}
    empty!(_params)
    for (k, v) in params  # Update params
        _params[k] = v
    end
    sort!(people, lt=(x, y) -> x.address <= y.address && x.birthdate >= y.birthdate)  # Group by SA2, then within SA2 sort from youngest to oldest
    for (i, person) in enumerate(people)
        person.id = i  # Rewrite ids
    end
    i1 = 0  # people[i1:i2] = people from SA2
    i2 = 0
    npeople        = length(people)
    hhold_dist     = indata["household_distribution"]
    primary_dist   = indata["primaryschool_distribution"]
    secondary_dist = indata["secondaryschool_distribution"]
    ncontacts_s2s  = Int(_params[:ncontacts_s2s])
    ncontacts_t2t  = Int(_params[:ncontacts_t2t])
    ncontacts_t2s  = Int(_params[:ncontacts_t2s])
    for i = 1:npeople  # Loop through SA2s. Could use a while loop but best to cap the number of iterations.
        i1 = i2 + 1
        sa2code = people[i1].address
        @info "$(now()) Populating $(sa2code) households, schools, communities"
        i2         = people_from_sa2(people, i1)
        people_sa2 = view(people, i1:i2)
        isempty(people_sa2) && continue
        id2index  = Dict(person.id => i for (i, person) in enumerate(people_sa2))
        age2first = persons.construct_age2firstindex(people_sa2, dt)
        hdist     = view(hhold_dist, hhold_dist.SA2_MAINCODE_2016 .== sa2code, :)
        populate_households!(people_sa2, dt, age2first, hdist, id2index)
        populate_school_contacts!(people_sa2, dt, age2first, primary_dist, secondary_dist, ncontacts_s2s, ncontacts_t2t, ncontacts_t2s, id2index)
        populate_community_contacts!(people_sa2, sa2code, id2index)
        i2 == npeople && break
    end
    @info "$(now()) Populating work places"
    id2index = Dict(person.id => i for (i, person) in enumerate(people))
    populate_workplaces!(people, dt, indata["workplace_distribution"], id2index)
    @info "$(now()) Populating social networks"
    populate_social_contacts!(people, id2index)
end

function get_contactlist(person::Person{A, S}, network::Symbol) where {A, S}
    ncontacts = 0
    if network == :household
        ncontacts = get_household_contactids!(person.i_household, person.id, contactids)
    elseif network == :school
        ncontacts = isnothing(person.school) ? 0 : get_school_contactids!(person.school, contactids)
    elseif network == :workplace
        if !isnothing(person.ij_workplace)
            i, j = person.ij_workplace
            ncontacts = get_regular_graph_contactids!(workplaces._workplaces[i], j, Int(_params[:n_workplace_contacts]), contactids)
        end
    elseif network == :community
        ncontacts = get_regular_graph_contactids!(community_networks.communitycontacts[person.address], person.i_community, Int(_params[:n_community_contacts]), contactids)
    elseif network == :social
        ncontacts = get_regular_graph_contactids!(social_networks.socialcontacts, person.i_social, Int(_params[:n_social_contacts]), contactids)
    end
    ncontacts
end

function get_household_contactids!(i_household, personid, contactids)
    j = 0
    flds = (:adults, :children)
    household = households._households[i_household]
    for fld in flds
        contactlist = getfield(household, fld)
        for contactid in contactlist
            contactid == personid && continue
            j += 1
            contactids[j] = contactid
        end
    end
    j
end

function get_school_contactids!(contactlist::Vector{Int}, contactids)
    ncontacts = length(contactlist)
    for j = 1:ncontacts
        contactids[j] = contactlist[j]
    end
    ncontacts
end

"""
Modified: contactids.

Populate contactids (global) with the person's contact IDs and return the number of contacts j.
I.e., contactids[1:j] is the required contact list.

The contacts are derived from a regular graph with ncontacts_per_person for each node.
"""
function get_regular_graph_contactids!(community::Vector{Int}, i_person::Int, ncontacts_per_person::Int, contactids::Vector{Int})
    i_person == 0 && return 0
    j = 0  # Index of contactids
    npeople = length(community)
    ncontacts_per_person = min(npeople - 1, ncontacts_per_person)
    halfn   = div(ncontacts_per_person, 2)
    i1 = rem(i_person - halfn + npeople, npeople)
    i1 = i1 == 0 ? npeople : i1
    i2 = rem(i_person + halfn, npeople)
    i2 = i2 == 0 ? npeople : i2
    if i1 < i2
        for i = i1:i2
            i == i_person && continue
            j += 1
            contactids[j] = community[i]
        end
    elseif i1 > i2
        for i = i1:npeople
            i == i_person && continue
            j += 1
            contactids[j] = community[i]
        end
        for i = 1:i2
            i == i_person && continue
            j += 1
            contactids[j] = community[i]
        end
    end
    if isodd(ncontacts_per_person)
        i  = rem(i_person + div(npeople, 2), npeople)
        i  = i == 0 ? npeople : i
        i == i_person && return j
        j += 1
        contactids[j] = community[i]
    end
    j
end

function people_from_sa2(people, i1)
    npeople = length(people)
    sa2     = people[i1].address
    for i = (i1 + 1):npeople
        people[i].address == sa2 && continue
        return i - 1  # Most recent person with address == sa2
    end
    npeople  # i2 == npeople
end

end