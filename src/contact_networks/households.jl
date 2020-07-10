module households

export populate_households!,populate_households_by_SA2!

using DataFrames
using Dates
using Distributions
using Logging

using ..utils
using ..persons

struct Household
    max_nadults::Int
    max_nchildren::Int
    adults::Vector{Int}    # ids
    children::Vector{Int}  # ids

    function Household(max_nadults, max_nchildren, adults, children)
        length(adults)   > max_nadults        && error("Household has too many adults")
        length(children) > max_nchildren      && error("Household has too many children")
        max_nadults < 0                       && error("Household must have a non-negative number of adults")
        max_nchildren < 0                     && error("Household must have a non-negative number of children")
        max_nadults + max_nchildren == 0      && error("Household must have at least 1 resident")
        max_nadults == 0 && max_nchildren > 0 && error("Household with children must have at least 1 adult")
        new(max_nadults, max_nchildren, adults, children)
    end
end

Household(max_nadults, max_nchildren) = Household(max_nadults, max_nchildren, Int[], Int[])

isfull(hh::Household) = (length(hh.adults) == hh.max_nadults) && (length(hh.children) == hh.max_nchildren)

"Attempts to add an adult to the household. Returns true if successful."
function push_adult!(hh::Household, id)
    length(hh.adults) >= hh.max_nadults && return false  # Household is full. No success.
    push!(hh.adults, id)  # Add person to household
    true  # Success
end

"Attempts to add a child to the household. Returns true if successful."
function push_child!(hh::Household, id)
    length(hh.children) >= hh.max_nchildren && return false  # Household is full. No success.
    push!(hh.children, id)  # Add person to household
    true  # Success
end

function populate_households!(people, dt::Date, SA2, age2first, age2last, household_distribution::DataFrame)
    #@info "$(now()) Populating households with children"
    populate_households_with_children!(people, dt, age2first, age2last, household_distribution)
    #@info "$(now()) Populating households without children"
    populate_households_without_children!(people, SA2, household_distribution)
end

################################################################################
# Households with children

"""
- Input data: 
  - d_nparents: Pr(nadults == k | nchildren > 0) = [0.26, 0.74]
  - d_nchildren: Pr(nchildren == k | nchildren > 0). E.g., [0.33, 0.4, 0.25, 0.01, 0.005, 0.005]
while n_unplaced_children > 0
    sample nchildren household from d_nchildren
    sample nadults from d_nparents
    construct household
    populate household
       - kids no more than (nchildren - 1) x 3 years apart
       - adults at least 20 years older than oldest child
    set household contacts
"""
function populate_households_with_children!(people, dt, age2first, age2last, household_distribution)
    family_household_distribution = construct_child_household_distribution(household_distribution)
    unplaced_children = Set{Int64}()
    unplaced_parents  = Set{Int64}() 
    for i = 0:18
        union!(unplaced_children,Set(age2first[i]:age2last[i]))
    end
    for i = 20:54
        union!(unplaced_parents, Set(age2first[i]:age2last[i]))  # Parents of children under 18 are adults aged between 20 and 54
    end
    imax = length(unplaced_children)
    for i = 1:imax  # Cap the number of iterations by placing at least 1 child per iteration
        # Init household
        hh  = draw_household_with_children(unplaced_parents, unplaced_children, family_household_distribution)
        np  = hh.max_nadults
        nc  = hh.max_nchildren
        idx = size(_households, 1) + 1  # _households[idx] = new household

        # Select children
        min_age = 0   # Minimum age of the next selected child
        max_age = 17  # Maximum age of the next selected child
        age_youngest_child = 1000
        age_oldest_child   = -1
        for j = 1:nc
            childid = sample_person_SA2(unplaced_children, min_age, max_age, age2first,age2last)
            pop!(unplaced_children, childid)
            push_child!(hh, childid)
            child = people[childid]
            child.i_household = idx
            age_years = age(child, dt, :year)
            age_youngest_child = age_years < age_youngest_child ? age_years : age_youngest_child
            age_oldest_child   = age_years > age_oldest_child   ? age_years : age_oldest_child
            min_age = max(0,  age_youngest_child - 3 * (nc - 1))
            max_age = min(17, age_oldest_child   + 3 * (nc - 1))
        end

        # Select parent/s
        min_parent_age = age_oldest_child + 20
        max_parent_age = age_oldest_child + 45
        for j = 1:np
            parentid = sample_person_SA2(unplaced_parents, min_parent_age, max_parent_age, age2first,age2last)
            pop!(unplaced_parents, parentid)
            push_adult!(hh, parentid)
            people[parentid].i_household = idx
        end
        push!(_households, hh)

        # Stopping criteria
        isempty(unplaced_children) && break
        isempty(unplaced_parents)  && break
    end
end

function construct_child_household_distribution(household_distribution::DataFrame)
    result = DataFrame(nadults=Int[], nchildren=Int[], nhouseholds=Int[])
    family_household_distribution = view(household_distribution, household_distribution.nchildren .> 0, :)
    for subdata in groupby(family_household_distribution, [:nadults, :nchildren])
        row = (nadults=subdata[1, :nadults], nchildren=subdata[1, :nchildren], nhouseholds=sum(subdata.nhouseholds))
        push!(result, row)
    end
    result[!, :proportion] = result.nhouseholds ./ sum(result.nhouseholds)
    result
end

function draw_household_with_children(unplaced_parents, unplaced_children, family_household_distribution::DataFrame)
    n_unplaced_parents  = length(unplaced_parents)
    n_unplaced_children = length(unplaced_children)
    i         = rand(Categorical(family_household_distribution.proportion))
    nparents  = family_household_distribution[i, :nadults]
    nparents  = nparents > n_unplaced_parents ? n_unplaced_parents : nparents
    nchildren = family_household_distribution[i, :nchildren]
    nchildren = nchildren > n_unplaced_children ? n_unplaced_children : nchildren
    Household(nparents, nchildren)
end

################################################################################
# Households without children

"""
- Input data:
  - d_nadults_without_children: Pr(nadults == k | nchildren == 0). E.g., Proportional to [0.24, 0.27, 0.02, 0.02, 0.01, 0.01].
while n_unplaced_adults > 0
    sample 1 household from d_nadults_without_children
    construct household
    populate household
        - No constraints at the moment
    set household contacts
"""
function populate_households_without_children!(people, SA2, household_distribution::DataFrame)
    nonfamily_household_distribution = construct_nonchild_household_distribution(household_distribution)
    unplaced_adults = Set([person.id for person in people if person.i_household == 0 && person.address == SA2])
    imax = length(unplaced_adults)
    for i = 1:imax  # Cap the number of iterations by placing at least 1 child per iteration
        # Init household
        hh  = draw_household_without_children(unplaced_adults, nonfamily_household_distribution)
        na  = hh.max_nadults
        idx = size(_households, 1) + 1  # _households[idx] = new household

        # Select adult/s
        for j = 1:na
            adultid = rand(unplaced_adults)
            pop!(unplaced_adults, adultid)
            push_adult!(hh, adultid)
            people[adultid].i_household = idx
        end
        push!(_households, hh)

        # Stopping criterion
        isempty(unplaced_adults) && break
    end
end

function construct_nonchild_household_distribution(household_distribution::DataFrame)
    result = DataFrame(nadults=Int[], nchildren=Int[], nhouseholds=Int[])
    nonfamily_household_distribution = view(household_distribution, household_distribution.nchildren .== 0, :)
    for subdata in groupby(nonfamily_household_distribution, [:nadults, :nchildren])
        row = (nadults=subdata[1, :nadults], nchildren=subdata[1, :nchildren], nhouseholds=sum(subdata.nhouseholds))
        push!(result, row)
    end
    result[!, :proportion] = result.nhouseholds ./ sum(result.nhouseholds)
    result
end

function draw_household_without_children(unplaced_adults, nonfamily_household_distribution::DataFrame)
    n_unplaced_adults = length(unplaced_adults)
    i       = rand(Categorical(nonfamily_household_distribution.proportion))
    nadults = nonfamily_household_distribution[i, :nadults]
    nadults = nadults > n_unplaced_adults  ? n_unplaced_adults : nadults
    Household(nadults, 0)
end

function populate_households_by_SA2!(people, dt::Date, SA2_list, household_distribution::DataFrame)
    for SA2 in SA2_list.SA2_code
        age2first = persons.construct_age2index_by_SA2(people,dt,SA2,true)
        age2last = persons.construct_age2index_by_SA2(people,dt,SA2,false)
        populate_households!(people, dt, SA2, age2first, age2last, household_distribution)
    end

end

################################################################################
# Constants

const _households = Household[]    # households[i].adults[j] is the id of the jth adult in the ith household. Ditto children.

end