module Demographics

export Person,     # Types
       contactids, # Constants
       construct_population, get_contactlist, save, load  # Functions

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

    @info "$(now()) Importing input data"
    indata = import_data(cfg.input_datadir, cfg.input_datafiles)

    @info "$(now()) Initialising population"
    agedist = indata["age_distribution"]
    npeople = round(Int, sum(agedist.count))
    people  = Vector{Person{Char, Nothing}}(undef, npeople)
    d_age   = Categorical(agedist.proportion)
    for id = 1:npeople
        age        = agedist[rand(d_age), :age]
        birthdate  = today() - Year(age)
        people[id] = Person{Char, Nothing}(id, birthdate, 'o', 'x', nothing)
    end

    @info "$(now()) Populating contacts"
    populate_contacts!(people, cfg.params, indata, today())
    people
end

end
