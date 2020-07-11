module utils

export import_data, sample_person, append_contact!, assign_contacts_regulargraph!, construct_agerange_indices

using CSV
using DataFrames
using LightGraphs

function import_data(datadir::String, tablename2datafile::Dict{String, String})
    result = Dict{String, DataFrame}()
    for (tablename, datafile) in tablename2datafile
        filename = joinpath(datadir, datafile)
        result[tablename] = DataFrame(CSV.File(filename))
    end
    result
end

function append_contact!(personid, contactid::Int, contactlist::Vector{Int})
    personid == contactid && return
    push!(contactlist, contactid)
end

"Randomly assign ncontacts to each person whose id is a value of vertexid2personid."
function assign_contacts_regulargraph!(people, contactcategory::Symbol, ncontacts::Int, vertexid2personid, id2index)
    nvertices = length(vertexid2personid)
    ncontacts = adjust_ncontacts_for_regular_graph(nvertices, ncontacts)  # Ensure a regular graph can be constructed
    g = random_regular_graph(nvertices, ncontacts)  # nvertices each with ncontacts (edges to ncontacts other vertices)
    adjlist = g.fadjlist
    for (vertexid, personid) in vertexid2personid
        i_person = id2index[personid]
        person   = people[i_person]
        contactlist_vertex = adjlist[vertexid]  # Contact list as vertexid domain...convert to personid domain
        contactlist_person = getproperty(person, contactcategory)
        if isnothing(contactlist_person)
            setproperty!(person, contactcategory, Int[])
            contactlist_person = getproperty(person, contactcategory)
        end
        for vertexid in contactlist_vertex
            append_contact!(personid, vertexid2personid[vertexid], contactlist_person)
        end
    end
end

"""
Require these conditions:
1. nvertices >= 1
2. ncontacts <= nvertices - 1
3. iseven(nvertices * ncontacts)

If required adjust ncontacts.
Return ncontacts.
"""
function adjust_ncontacts_for_regular_graph(nvertices, ncontacts)
    nvertices == 0 && error("The number of vertices must be at least 1")
    ncontacts = ncontacts > nvertices - 1 ? nvertices - 1 : ncontacts
    iseven(nvertices * ncontacts) ? ncontacts : ncontacts - 1
end

"""
Return the id of a random person whose is unplaced and in the specified age range.
If one doesn't exist return a random id from unplaced_people.
"""
function sample_person(unplaced_people::Set{Int}, people, min_age, max_age, age2first, npeople)
    i1_i2 = construct_agerange_indices(age2first, min_age, max_age, npeople)
    n     = length(i1_i2)  # Maximum number of random draws
    for i = 1:n
        index = rand(i1_i2)  # Index of a random person in the age range
        id    = people[index].id
        id in unplaced_people && return index, id  # id is also an unplaced person
    end
    index = rand(unplaced_people)
    index, people[index].id
end

"""
Return the indices (as a Range) of people aged between min_age and max_age inclusive.
We can use age2first instead of the entire people vector.
"""
function construct_agerange_indices(age2first, min_age, max_age, npeople)
    i1 = 0
    i2 = 0
    for age = min_age:130
        !haskey(age2first, age) && continue
        if i1 == 0
            if age <= max_age
                i1 = age2first[age]
            else
                return 0:0  # There are no people in the required age range
            end
        end
        if i2 == 0 && age > max_age
            i2 = age2first[age] - 1
            break
        end
    end
    i2 > 0 && return i1:i2
    i1:npeople
end

end