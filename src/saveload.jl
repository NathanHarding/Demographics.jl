module saveload

export save, load

using JSON3

using ..persons
using ..contacts.households
using ..contacts.workplaces
using ..contacts.social_networks
using ..contacts.community_networks

# Enable JSON3 to read/write
JSON3.StructTypes.StructType(::Type{Person{A, S}}) where {A, S} = JSON3.StructTypes.Mutable()
JSON3.StructTypes.StructType(::Type{Household}}) = JSON3.StructTypes.Struct()

Person{A, S}() where {A, S} = Person(0, Date(1900, 1, 1), 'f', undef, undef, 0, nothing, nothing, 0, 0)
Households.Household()      = Households.Household(0, 0, Int[], Int[])

function save(people::Vector{Person{A, S}}, filename::String) where {A, S}
    d = Dict{String, Any}()
    d["people"]            = people
    d["households"]        = households._households
    d["workplaces"]        = workplaces._workplaces
    d["communitycontacts"] = community_networks.communitycontacts
    d["socialcontacts"]    = social_networks.socialcontacts
    s = JSON3.write(d)
    write(s, filename)
end

function load(filename::String)
    #s = String(read(filename))
end

end