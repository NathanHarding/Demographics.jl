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
    agedist = indata["age_distribution"]
    sa2_pops = indata["cumsum_population"]
    npeople = round(Int, sum(agedist.count))
    people  = Vector{Person{Int, Nothing}}(undef, npeople)
    d_age   = Categorical(agedist.proportion)
    SA2_id = 1
    for id = 1:npeople
        while (id - sa2_pops.cumsum_population[SA2_id] > 0)
            SA2_id +=1
        end
        age        = agedist[rand(d_age), :age]
        birthdate  = today() - Year(age)
        people[id] = Person{Int64, Nothing}(id, birthdate, 'o', sa2_pops.SA2_code[SA2_id], nothing)
    end

    @info "$(now()) Populating contacts"
    populate_contacts!(people, cfg.params, indata, today())
    people
end

end
