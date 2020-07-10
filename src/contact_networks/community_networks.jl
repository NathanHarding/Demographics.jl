module community_networks

export populate_community_contacts!

using Random  # shuffle!

const communitycontacts = Dict{Int, Vector{Int}}()  # Each key is an SA2 code where the value pair contains a vector of person IDs. Community contacts can be derived for each person 

function populate_community_contacts!(people, id2index)
    community_contacts = Int[]
    for person in people
        push!(community_contacts, person.id)
    end
    shuffle!(community_contacts)
    for (i, id) in enumerate(community_contacts)
        i_people = id2index[id]
        people[i_people].i_community = i
    end
    community_contacts
end


function populate_community_contacts!(people, sa2code, id2index)
    communitycontacts[sa2code] = populate_community_contacts!(people, id2index)
end

end