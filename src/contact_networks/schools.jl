"""
School contacts for teachers and people under 23.

Children under 5 are assumed to attend child care.
Children aged 5 to 17 inclusive are assumed to attend school.
Adults aged 18 to 23 inclusive are assumed to attend post-secondary education.
"""
module schools

export populate_school_contacts!, populate_SA2_schools!

using DataFrames
using Dates
using Distributions

using ..utils
using ..persons

"""
Each teacher can contact N1 other teachers and N2 students from any age group.
Each student can contact N3 students in their age group.
"""
mutable struct School
    max_nteachers::Int
    max_nstudents_per_level::Int
    teachers::Vector{Int}
    age2students::Dict{Int, Vector{Int}}  # Classes: age => [childid1, ...]

    function School(max_nteachers, max_nstudents_per_level, teachers, age2students)
        max_nstudents_per_level < 1 && error("max_nstudents_per_level must be at least 1")
        new(max_nteachers, max_nstudents_per_level, teachers, age2students)
    end
end

function School(schooltype::Symbol,
                primaryschool_distribution::DataFrame, secondaryschool_distribution::DataFrame,
                d_nstudents_per_level_primary, d_nstudents_per_level_secondary)
    # Construct max_nstudents_per_level, age2students and the teacher-student ratio
    if schooltype == :childcare
        max_nstudents_per_level = 20
        teacher2student_ratio   = 1 / 15  # Need at least 1 teacher to 15 students
        age2students = Dict(age => Int[] for age = 0:4)
    elseif schooltype == :primary
        max_nstudents_per_level = draw_nstudents_per_level(primaryschool_distribution, d_nstudents_per_level_primary)
        teacher2student_ratio   = 1 / 15
        age2students = Dict(age => Int[] for age = 5:11)
    elseif schooltype == :secondary
        max_nstudents_per_level = draw_nstudents_per_level(secondaryschool_distribution, d_nstudents_per_level_secondary)
        teacher2student_ratio   = 1 / 15
        age2students = Dict(age => Int[] for age = 12:17)
    elseif schooltype == :tertiary
        teacher2student_ratio   = 1 / 40
        max_nstudents_per_level = 1000
        age2students = Dict(age => Int[] for age = 18:23)
    else
        error("Unknown school type")
    end

    # Calculate the number of required teachers
    nlevels       = length(age2students)
    max_nstudents = nlevels * max_nstudents_per_level
    max_nteachers = round(Int, teacher2student_ratio * max_nstudents)
    School(max_nteachers, max_nstudents_per_level, Int[], age2students)
end

function draw_nstudents_per_level(school_distribution::DataFrame, d_nstudents_per_level)
    i  = rand(d_nstudents_per_level)
    lb = school_distribution[i, :avg_year_level_size_lb]
    ub = school_distribution[i, :avg_year_level_size_ub]
    round(Int, 0.5 * (lb + ub))
end

function determine_schooltype(age::Int)
    age <= 4  && return :childcare
    age <= 11 && return :primary
    age <= 17 && return :secondary
    age <= 23 && return :tertiary
    error("Person with age $(age) cannot be assigned as a student to a school")
end

function isfull(school::School)
    length(school.teachers) >= school.max_nteachers && return true
    for (age, students) in school.age2students
        length(students) < school.max_nstudents_per_level && return false  # Room in this age group
    end
    true
end

function push_teacher!(school::School, id::Int)
    length(school.teachers) >= school.max_nteachers && return false  # Teacher positions are full. No success.
    push!(school.teachers, id)  # Add teacher to school
    true  # Success
end

function push_student!(school::School, id::Int, age::Int)
    v = school.age2students[age]
    length(v) >= school.max_nstudents_per_level && return false  # Child positions are full. No success.
    push!(v, id)  # Add teacher to school
    true  # Success
end

function populate_school_contacts!(people, dt::Date, age2first,
                                   primaryschool_distribution::DataFrame, secondaryschool_distribution::DataFrame,
                                   ncontacts_s2s, ncontacts_t2t, ncontacts_t2s, id2index)
    d_nstudents_per_level_primary   = Categorical(primaryschool_distribution.proportion)
    d_nstudents_per_level_secondary = Categorical(secondaryschool_distribution.proportion)
    npeople           = length(people)
    min_teacher_age   = 24
    max_teacher_age   = 65
    unplaced_teachers = Set(construct_agerange_indices(age2first, min_teacher_age, max_teacher_age, npeople))
    unplaced_students = Dict{Int, Set{Int}}()
    for age = 0:23
        rg = construct_agerange_indices(age2first, age, age, npeople)
        rg == 0:0 && continue
        unplaced_students[age] = Set(rg)
    end
    imax = sum([length(v) for (k, v) in unplaced_students])
    for i = 1:imax  # Cap the number of iterations by placing at least 1 child per iteration
        # Init school
        i_people = nothing
        for age = 0:23
            !haskey(unplaced_students, age) && continue
            isempty(unplaced_students[age]) && continue
            r = rand(unplaced_students[age])
            r == 0 && continue
            i_people = r
            break
        end
        isnothing(i_people) && break  # STOPPING CRITERION: There are no unplaced students remaining
        student    = people[i_people]
        schooltype = determine_schooltype(age(student, dt, :year))
        school     = School(schooltype,
                            primaryschool_distribution, secondaryschool_distribution,
                            d_nstudents_per_level_primary, d_nstudents_per_level_secondary)

        # Fill student positions
        age2students = school.age2students
        for (age, students) in age2students
            n_available = school.max_nstudents_per_level - length(students)  # Number of available positions
            for j = 1:n_available
                !haskey(unplaced_students, age) && break
                isempty(unplaced_students[age]) && break
                index, studentid = sample_person(unplaced_students[age], people, age, age, age2first, npeople)
                pop!(unplaced_students[age], index)
                push_student!(school, studentid, age)
            end
        end

        # Fill teacher positions
        n_available = school.max_nteachers - length(school.teachers)  # Number of available positions
        for j = 1:n_available
            isempty(unplaced_teachers) && break
            index, teacherid = sample_person(unplaced_teachers, people, min_teacher_age, max_teacher_age, age2first, npeople)
            pop!(unplaced_teachers, index)
            push_teacher!(school, teacherid)
        end

        # Set contact lists
        set_student_to_student_contacts!(people, school, ncontacts_s2s, id2index)
        set_teacher_to_teacher_contacts!(people, school, ncontacts_t2t, id2index)
        set_teacher_to_student_contacts!(people, school, ncontacts_t2s, id2index)
    end
end

function set_student_to_student_contacts!(people, school::School, ncontacts_s2s, id2index)
    age2students = school.age2students
    for (age, students) in age2students
        isempty(students) && continue
        vertexid2personid = Dict(i => studentid for (i, studentid) in enumerate(students))
        assign_contacts_regulargraph!(people, :school, min(ncontacts_s2s, length(students)), vertexid2personid, id2index)
    end
end

function set_teacher_to_teacher_contacts!(people, school::School, ncontacts_t2t, id2index)
    teachers = school.teachers
    isempty(teachers) && return
    vertexid2personid = Dict(i => teacherid for (i, teacherid) in enumerate(teachers))
    assign_contacts_regulargraph!(people, :school, min(ncontacts_t2t, length(teachers)), vertexid2personid, id2index)
end

function set_teacher_to_student_contacts!(people, school::School, ncontacts_t2s, id2index)
    # Construct a vector of all studentids in the school
    studentids = Int[]
    for (age, students) in school.age2students
        for studentid in students
            push!(studentids, studentid)
        end
    end
    nstudents = length(studentids)

    # For each teacher, cycle through the students until the teacher has enough contacts
    teachers = school.teachers
    ncontacts_t2s = min(ncontacts_t2s, nstudents)  # Can't contact more students than are in the school
    idx = 0
    for teacherid in teachers
        i_teacher = id2index[teacherid]
        teacher_contactlist = people[i_teacher].school
        for i = 1:ncontacts_t2s
            idx += 1
            idx  = idx > nstudents ? 1 : idx
            studentid = studentids[idx]
            i_student = id2index[studentid]
            student_contactlist = people[i_student].school
            append_contact!(teacherid, studentid, teacher_contactlist)
            append_contact!(studentid, teacherid, student_contactlist)
        end
    end
end

end