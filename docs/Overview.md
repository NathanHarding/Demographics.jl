# Overview

## People

A person is represented by a `Person` struct, which includes the fields:

- `id` (Int)
- `birthdate` (Date)
- `sex` (Char, `m`, `f` or `o`)
- `address` (any type)
- `state` (any type)

The address type can be chosen as required. For example it may be a `struct` representing a full street address,
a `Tuple` of lat-lon coordinates, a `String` containing a suburb/city name, an `Int` containing the postcode, etc.

The `state` contains the non-demographic variables of interest, the values of which typically change over time.
Examples include disease status, employment status, net wealth, etc.

The population of interest is constructed from ABS data, which gives an estimated population by age, sex and SA2.

## Contacts

Networks of people are constructed by endowing each person with 5 contact lists, each being a vector of the IDs of other people in the population.
Each of the 5 lists represents one of the following settings:

- Household: The people you live with.
- Social:    Family and friends that you don't live with.
- School:    People you see at school.
- Workplace: People you work with. Applicable if you don't attend school and don't work at a school.
- Community: Strangers that you interact with when shopping, commuting, visiting the public library, cinema, etc.

Each member of the population is allocated to a household as follows:

1. Household data from the ABS gives an estimated count of households by household size, and also family composition.
   We use this data to construct a simplified set households consisting of households with children and 1 or 2 parents,
   and households without children.
2. Households with children are constucted by:
   - Randomly drawing a household from the set of constructed households (with the numbers of adults and children determined)
   - Randomly draw the children such that they are no more than 5 years apart
   - Randomly draw the parent or parents such that they are no more than 45 years older than the oldest child
3. Households without children are then populated using random allocation of remaining adults.

Schools are constructed from DET data that gives the number of children in each year level for individual schools.
Children aged 5-17 are allocated to schools at random with their age matched to their year level.
Teachers are allocated according to a fixed teacher:student ratio of 1:15.
Contacts among children are constructed using a regular graph - each member has the same number of contacts, thus inducing many common contacts between 2 neighouring students in the graph, but also some different contacts.
Contacts among teachers are also constructed as regular graphs.
Contacts between students and teachers are constructed by teachers having a fixed number of student contacts.

Child care centres are constructed for children aged 0 to 4 in a similar way.
Since we lack data we assume that a child care centre has a room for each age group containing 20 children.

Universities and TAFES are constructed similarly for adults aged 18 to 23.
We assume 1000 students per age group and a teacher:student ratio of 1:40.

Work places are constructed from ABS data concerning the number of employees and populated randomly with remaining adults.
Contacts within work places are constructed as regular graphs.

Social and community contacts are regular within the entire population.