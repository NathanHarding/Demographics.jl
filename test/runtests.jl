using Test
using Demographics

using Dates
using Logging


@info "$(now()) Constructing population"
configfile = joinpath(pwd(), "config", "config.yml")
people = construct_population(configfile)

@info "$(now()) Saving population to disk"  # As well as households, workplaces, social contacts and community contacts
outdir = joinpath(pwd(), "data", "output")
save(people, outdir)

@info "$(now()) Loading population from disk"  # As well as households, workplaces, social contacts and community contacts
people2 = load(outdir)

@test length(people) == length(people2)
#@test people[1] == people2[1]
#@test people[end] == people2[end]
