module social_networks

export populate_social_contacts!

using Random

const socialcontacts = Int[]   # Contains person IDs. Social contacts can be derived for each person.

function populate_social_contacts!(agents)
    npeople = length(agents)
    for i = 1:npeople
        push!(socialcontacts, agents[i].id)
    end
    shuffle!(socialcontacts)
    for i = 1:npeople
        id = socialcontacts[i]
        agents[id].i_social = i
    end
end

end