using Test
using Demographics

using Dates
using Logging

@info "$(now()) Constructing population"
configfile = joinpath(pwd(), "config", "config.yml")
people = construct_population(configfile)

@info "$(now()) Saving population to disk"  # As well as households, workplaces, social contacts and community contacts
outfile = joinpath(pwd(), "data", "output", "population.json")
save(people, outfile)

@info "$(now()) Loading population from disk"  # As well as households, workplaces, social contacts and community contacts
popn = load(outfile)