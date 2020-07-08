module utils

export import_data, sample_person, sample_person_SA2, append_contact!, assign_contacts_regulargraph!

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
function assign_contacts_regulargraph!(people, contactcategory::Symbol, ncontacts::Int, vertexid2personid)
    nvertices = length(vertexid2personid)
    ncontacts = adjust_ncontacts_for_regular_graph(nvertices, ncontacts)  # Ensure a regular graph can be constructed
    g = random_regular_graph(nvertices, ncontacts)  # nvertices each with ncontacts (edges to ncontacts other vertices)
    adjlist = g.fadjlist
    for (vertexid, personid) in vertexid2personid
        person = people[personid]
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
function sample_person(unplaced_people::Set{Int}, min_age, max_age, age2first)
    i1 = age2first[min_age]
    i2 = age2first[max_age + 1] - 1
    s  = i1:i2      # Indices of people in the age range
    n  = length(s)  # Maximum number of random draws
    for i = 1:n
        id = rand(s)  # id is a random person in the age range
        id in unplaced_people && return id  # id is also an unplaced person
    end
    rand(unplaced_people)
end
function sample_person_SA2(unplaced_people::Set{Int}, min_age, max_age, age2first,age2last)
    i1 = age2first[min_age]
    i2 = age2last[max_age]
    s  = i1:i2      # Indices of people in the age range
    n  = length(s)  # Maximum number of random draws
    for i = 1:n
        id = rand(s)  # id is a random person in the age range
        id in unplaced_people && return id  # id is also an unplaced person
    end
    rand(unplaced_people)
end

end