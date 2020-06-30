using Pkg
Pkg.activate(".")

using YAML
#functions
function generate_input_files(subpop_module,home_dir)
    if subpop_module == true
        @info "creating subpopulation list file"
        include("generate_subpopulation.jl")
        cd(home_dir)
    end

    @info "creating subpopulation age file"
    include("population_by_age.jl")
    cd(home_dir)

    @info "creating workplace file"
    include("workplaces_by_size.jl")
    cd(home_dir)

    @info "creating household file"
    include("households.jl")
    cd(home_dir)

    #@info "creating school file"
    #include("school sizes.jl")
    #cd(home_dir)
end

#script
cfg=YAML.load(open("scripts\\config.yml"))
generate_input_files(cfg["subpop_module"],cfg["home_dir"])