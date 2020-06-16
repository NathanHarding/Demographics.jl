module Demographics

export Person, Household, School,  # Types
       contactids, workplaces, communitycontacts, socialcontacts,  # Constants
       populate_contacts!, get_contactlist  # Functions

using Dates
using Distributions
using Logging

include("utils.jl")               # Independent
include("persons.jl")             # Independent
include("households.jl")          # Depends on: utils, persons
include("schools.jl")             # Depends on: utils, persons
include("workplaces.jl")          # Depends on: persons
include("social_networks.jl")     # Independent
include("community_networks.jl")  # Independent

using .utils
using .persons
using .households
using .schools
using .workplaces
using .social_networks
using .community_networks

const contactids = fill(0, 100)   # Buffer for a mutable contact list

function populate_contacts!(people::Vector{Person{A, S}}, params, indata, dt::Date) where {A, S}
    age2first = persons.construct_age2firstindex!(people, dt)  # people[age2first[i]] is the first agent with age i
    populate_households!(people, dt, age2first, indata["household_distribution"])
    @info "$(now()) Populating schools"
    populate_school_contacts!(people, dt, age2first, indata["primaryschool_distribution"], indata["secondaryschool_distribution"],
                              Int(params[:ncontacts_s2s]), Int(params[:ncontacts_t2t]), Int(params[:ncontacts_t2s]))
    @info "$(now()) Populating work places"
    populate_workplaces!(people, dt, indata["workplace_distribution"])
    @info "$(now()) Populating communities"
    populate_community_contacts!(people)
    @info "$(now()) Populating social networks"
    populate_social_contacts!(people)
end

function get_contactlist(person::Person{A, S}, network::Symbol, params) where {A, S}
    ncontacts = 0
    if network == :household
        ncontacts = get_household_contactids!(person.i_household, person.id, contactids)
    elseif network == :school
        ncontacts = isnothing(person.school) ? 0 : get_school_contactids!(person.school, contactids)
    elseif network == :workplace
        if !isnothing(person.ij_workplace)
            i, j = person.ij_workplace
            ncontacts = get_regular_graph_contactids!(workplaces._workplaces[i], j, Int(params[:n_workplace_contacts]), contactids)
        end
    elseif network == :community
        ncontacts = get_regular_graph_contactids!(community_networks.communitycontacts, person.i_community, Int(params[:n_community_contacts]), contactids)
    elseif network == :social
        ncontacts = get_regular_graph_contactids!(social_networks.socialcontacts, person.i_social, Int(params[:n_social_contacts]), contactids)
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

end
