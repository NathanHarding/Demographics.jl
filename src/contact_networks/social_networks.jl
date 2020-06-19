module social_networks

export populate_social_contacts!

using Random

const socialcontacts = Int[]   # Contains person IDs. Social contacts can be derived for each person.

function populate_social_contacts!(people)
    npeople = length(people)
    for i = 1:npeople
        push!(socialcontacts, people[i].id)
    end
    shuffle!(socialcontacts)
    for i = 1:npeople
        id = socialcontacts[i]
        people[id].i_social = i
    end
end

end