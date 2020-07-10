module community_networks

export populate_community_contacts!, populate_community_contacts_by_SA2!

using Random

# const communitycontacts = Int[]   # Contains person IDs. Community contacts can be derived for each person.
const communitycontacts = Dict{Int,Array{Int,1}}()   # Each key is an SA2 code where the value pair contains a vector of person IDs. Community contacts can be derived for each person 

function populate_community_contacts!(people,SA2)
	community_contacts = Int[]
	idxs = findall(x->x.address == SA2,people)      #Exploits sorted structure of people. people[i].id = i
    npeople = length(idxs)
    for idx in idxs
        push!(community_contacts, idx)
    end
    shuffle!(community_contacts)
    for i = 1:npeople
        id = community_contacts[i]
        people[id].i_community = i
    end
    community_contacts
end


function populate_community_contacts_by_SA2!(people,SA2)
    communitycontacts[SA2] = populate_community_contacts!(people, SA2)
end

end