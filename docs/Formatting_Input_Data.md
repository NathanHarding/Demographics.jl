# Formatting Input Data

The input data for constructing a population is itself constructed from data from the ABS and DET using `scripts/generate_population_files.jl`.

## Inputs

- A YAML file containing config information for the construction. See `scripts/config.yml` for an example.
- A list of regions to be included in the model. The list contains SA2, SA3 or SA4 codes.

## Outputs

- `generate_subpopulation.jl`: Convert the list of regions into the set of SA2 codes that comprises the supplied list of regions.
- `population_by_age.jl`:
    - A table containing the age distribution for each SA2. Each column is a distribution for a SA2.
    - A table containing the total population of each SA2. Each row contains the total population of a SA2.
- `workplaces_by_size.jl`: A table containing the work place distribution over the union of SA2s in the population.
- `households.jl`: A table containing, for each SA2, the number of households of each composition, where composition
is specified by the number of adults and the number of children in the houusehold.
- `school_sizes.jl`:
    - A table of actual schools within the specified SA2s. Each school occupies 12 rows, 1 row per year level. Each row specifies the number of students in the year level.
    - Two tables, 1 primary and 1 secondary, containing the distribution of school sizes within the specified SA2s. The sample space is a set of average year-level sizes.