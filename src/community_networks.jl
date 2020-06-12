module community_networks

using Random

const communitycontacts = Int[]   # Contains person IDs. Community contacts can be derived for each person.

function populate_community_contacts!(agents)
    npeople = length(agents)
    for i = 1:npeople
        push!(communitycontacts, agents[i].id)
    end
    shuffle!(communitycontacts)
    for i = 1:npeople
        id = communitycontacts[i]
        agents[id].i_community = i
    end
end

end