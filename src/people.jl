module people

export Person, age

using Dates

mutable struct Person{A, S}
    id::Int
    birthdate::Date
    sex::Char   # 'm', 'f', or 'o'
    address::A  # Any description of location that is fit for purpose. E.g., full address, postcode, suburb name, city, country, etc.
    state::S    # contains non-demographic variables whose values typically change over time. E.g., disease status, socioeconomic status, etc

    # Contact networks
    i_household::Int  # Person is in households[i_household].
    school::Union{Nothing, Vector{Int}}  # Child care, primary school, secondary school, university. Not empty for teachers and students.
    ij_workplace::Union{Nothing, Tuple{Int, Int}}  # Empty for children and teachers (whose workplace is school). person.id == workplaces[i][j].
    i_community::Int  # Shops, transport, pool, library, etc. communitycontacts[i_community] == person.id
    i_social::Int     # Family and/or friends outside the household. socialcontacts[i_social] == person.id
end

Person(id, birthdate, sex, address, state) = Person(id, birthdate, sex, address, state, 0, nothing, nothing, 0, 0)

################################################################################
# Convenience functions

"Age of person on dt, with unit one of :day, :month or :year."
function age(person::Person, dt::Date, unit::Symbol)
    birthdate = person.birthdate
    dt < birthdate && return nothing
    result = 0
    if unit == :day
        result = Dates.value(dt - birthdate)
    elseif unit == :month
        dt1 = birthdate
        while true  # Count months from birthdate
            dt1 += Month(1)
            if dt1 <= dt
                result += 1
            else
                break
            end
        end
    elseif unit == :year
        dt1 = birthdate
        while true  # Count years from birthdate
            dt1 += Year(1)
            if dt1 <= dt
                result += 1
            else
                break
            end
        end
    else
        error("Unknown time unit: $(unit)")
    end
    result
end

end