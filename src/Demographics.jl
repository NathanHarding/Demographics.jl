module Demographics

export Person,     # Types
       contactids, # Constants
       construct_population, get_contactlist, getcontact, save, load  # Functions

using Dates
using Distributions
using Logging

include("config.jl")    # Independent
include("utils.jl")     # Independent
include("persons.jl")   # Independent
include("contacts.jl")  # Depends on: utils, persons, households, schools, workplaces, social_networks, community_networks
include("saveload.jl")

using .config
using .utils
using .persons
using .contacts
using .saveload

function construct_population(configfile::String)
    @info "$(now()) Configuring run"
    cfg = Config(configfile)
    construct_population(cfg)
end

function construct_population(cfg::Config)
    @info "$(now()) Importing input data"
    indata = import_data(cfg.input_datadir, cfg.input_datafiles)

    @info "$(now()) Initialising population"
    agedist  = indata["age_distribution"]  # Each column is an age distribution for an SA2
    sa2_pops = indata["cumsum_population"]
    npeople  = sa2_pops.cumsum_population[end]
    people   = Vector{Person{Int, Nothing}}(undef, npeople)
    SA2_id   = 1
    d_age    = Categorical(agedist[!, Symbol(sa2_pops.SA2_code[SA2_id])])  # Age distribution for the 1st SA2
    for id = 1:npeople
        while (id - sa2_pops.cumsum_population[SA2_id] > 0)  # Current SA2 is full. Move to the next SA2.
            SA2_id += 1
            if sum(agedist[!, Symbol(sa2_pops.SA2_code[SA2_id])]) != 0
                d_age = Categorical(agedist[!, Symbol(sa2_pops.SA2_code[SA2_id])])
            end
        end
        age        = agedist[rand(d_age), :age]
        birthdate  = today() - Year(age)
        address    = sa2_pops.SA2_code[SA2_id]
        people[id] = Person{Int64, Nothing}(id, birthdate, 'o', address, nothing)
    end

    @info "$(now()) Populating contacts"
    populate_contacts!(people, cfg.params, indata, today())
    people
end

end
