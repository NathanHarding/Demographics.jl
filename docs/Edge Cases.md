# Edge Cases

Here we list some corner cases in the population construction described in the [Overview](Overview.md).
When constructing the population a warning is printed to STDOUT in these cases.

1. The data for some SA2s include people but no households.

For example, SA2 205031092 (Wilson's Promontory) has 5 people and no household data.
Wilson's Promontory is a national park, and these 5 people happened to be there on census night.
We remove these people from the population as we have no way of allocating them to a household, schools, work places, etc.

2. Some SA2s have children but no households with children.

For example, SA2 208031184 (Braeside) has 37 people including 18 children.
However the household data shows just 4 households each with 1 adult and no children.
In this case we can fabricate households with children.