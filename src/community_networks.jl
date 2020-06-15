module community_networks

export populate_community_contacts!

using Random

const communitycontacts = Int[]   # Contains person IDs. Community contacts can be derived for each person.

function populate_community_contacts!(people)
    npeople = length(people)
    for i = 1:npeople
        push!(communitycontacts, people[i].id)
    end
    shuffle!(communitycontacts)
    for i = 1:npeople
        id = communitycontacts[i]
        people[id].i_community = i
    end
end

end