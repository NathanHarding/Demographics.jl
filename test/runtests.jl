using Test
using Demographics

# Construct population
configfile = joinpath(pwd(), "config", "config.yml")
people = construct_population(configfile)

#=
# Save population to disk (as well as households, workplaces, social contacts and community contacts)
outfile = ""
save(people, outfile)

# Load population from disk (as well as households, workplaces, social contacts and community contacts)
pop = load(outfile)
=#