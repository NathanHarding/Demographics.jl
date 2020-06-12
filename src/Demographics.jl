module Demographics

export Person, Household, School,  # Types
       contactids, workplaces, communitycontacts, socialcontacts,  # Constants
       populate_contacts!  # Functions

using Dates
using Distributions
using Logging

include("people.jl")              # Independent
include("utils.jl")               # Depends on: people
include("households.jl")          # Depends on: utils
include("schools.jl")             # Depends on: utils
include("workplaces.jl")          # Independent
include("social_networks.jl")     # Independent
include("community_networks.jl")  # Independent

using .people
using .utils
using .households
using .schools
using .workplaces
using .social_networks
using .community_networks

const contactids = fill(0, 100)   # Buffer for a mutable contact list

function populate_contacts!(people::Vector{Person}, params, indata)
    age2first = utils.construct_age2firstindex!(people, today())  # people[age2first[i]] is the first agent with age i
    populate_households!(people, age2first, indata["household_distribution"])
    @info "$(now()) Populating schools"
    populate_school_contacts!(people, age2first, indata["primaryschool_distribution"], indata["secondaryschool_distribution"],
                              params[:ncontacts_s2s], params[:ncontacts_t2t], params[:ncontacts_t2s])
    @info "$(now()) Populating work places"
    populate_workplace_contacts!(people, params[:n_workplace_contacts], indata["workplace_distribution"])
    @info "$(now()) Populating communities"
    populate_community_contacts!(people)
    @info "$(now()) Populating social networks"
    populate_social_contacts!(people)
end

end
