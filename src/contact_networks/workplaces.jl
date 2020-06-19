module workplaces

export populate_workplaces!

using DataFrames
using Dates
using Distributions

using ..persons

const _workplaces = Vector{Int}[]  # workplaces[i][j] is the id of the jth worker in the ith workplace.

function populate_workplaces!(people, dt::Date, workplace_distribution::DataFrame)
    d_nworkers       = Categorical(workplace_distribution.proportion)  # Categories are: 0 employees, 1-4, 5-19, 20-199, 200+
    unplaced_workers = Set([person.id for person in people if age(person, dt, :year) > 23 && isnothing(person.school)])
    imax = length(unplaced_workers)
    for i = 1:imax
        isempty(unplaced_workers) && break
        nworkers  = draw_nworkers(workplace_distribution, d_nworkers)
        nworkers  = nworkers > length(unplaced_workers) ? length(unplaced_workers) : nworkers
        workplace = fill(0, nworkers)
        idx       = size(_workplaces, 1) + 1  # _workplaces[idx] = new workplace
        for j = 1:nworkers
            workerid = rand(unplaced_workers)
            pop!(unplaced_workers, workerid)
            workplace[j] = workerid
            people[workerid].ij_workplace = (idx, j)
        end
        push!(_workplaces, workplace)
    end
end

function draw_nworkers(workplace_distribution::DataFrame, d_workplace_size)
    i  = rand(d_workplace_size)
    lb = workplace_distribution[i, :nemployees_lb]
    ub = workplace_distribution[i, :nemployees_ub]
    rand(lb:ub) + 1
end

end