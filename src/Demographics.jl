module Demographics

export Person, Household, School,  # Types
       contactids, workplaces, communitycontacts, socialcontacts,  # Constants
       populate_contacts!  # Functions

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

function populate_contacts!(people::Vector{Person}, params, indata, dt::Date)
    age2first = persons.construct_age2firstindex!(people, dt)  # people[age2first[i]] is the first agent with age i
    populate_households!(people, dt, age2first, indata["household_distribution"])
    @info "$(now()) Populating schools"
    populate_school_contacts!(people, dt, age2first, indata["primaryschool_distribution"], indata["secondaryschool_distribution"],
                              params[:ncontacts_s2s], params[:ncontacts_t2t], params[:ncontacts_t2s])
    @info "$(now()) Populating work places"
    populate_workplaces!(people, dt, indata["workplace_distribution"])
    @info "$(now()) Populating communities"
    populate_community_contacts!(people)
    @info "$(now()) Populating social networks"
    populate_social_contacts!(people)
end

end
