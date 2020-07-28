module social_networks

export populate_social_contacts!

using Random

const socialcontacts = Int[]   # Contains person IDs. Social contacts can be derived for each person.

function populate_social_contacts!(people, id2index)
    for person in people
        push!(socialcontacts, person.id)
    end
    shuffle!(socialcontacts)
    for (i, id) in enumerate(socialcontacts)
        i_people = id2index[id]
        people[i_people].i_social = i
    end
end

end