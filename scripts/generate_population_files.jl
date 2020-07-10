#=
  Contents: Master script for formatting input data.

  To run it:

  $ cd /path/to/Demographics.jl
  $ julia
  julia> include("scripts\\generate_population_files.jl")
=#

using Pkg
Pkg.activate(".")

using CSV
using DataFrames
using Dates
using Logging
using YAML

@info "$(now()) Configuring formatting job"
cfg = YAML.load(open("scripts\\config.yml"))

@info "$(now()) Creating subpopulation list file"
include("generate_subpopulation.jl")

@info "$(now()) Creating subpopulation age file"
include("population_by_age.jl")

@info "$(now()) Creating workplace file"
include("workplaces_by_size.jl")

@info "$(now()) Creating household file"
include("households.jl")

@info "$(now()) Creating school file"
include("school_sizes.jl")
nothing