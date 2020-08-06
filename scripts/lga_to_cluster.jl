#=
  Content: Map each LGA to a health service cluster.
=#

using CSV
using DataFrames

################################################################################
# Functions

function lga_to_cluster(data::DataFrame)
    lga2cluster = Dict{String, String}()  # lga => cluster
    for subdata in groupby(data, "LGA Name")
        # Count the occurrences of each cluster
        d = Dict{String, Int}()  # Cluster => count
        for row in eachrow(subdata)
            k    = row["COVID Region Cluster"]
            d[k] = haskey(d, k) ? d[k] + 1 : 1
        end

        # Find the cluster with the highest count
        maxcount = 0
        cluster  = ""
        for (_cluster, n) in d
            n <= maxcount && continue
            maxcount = n
            cluster  = _cluster
        end
        lga = subdata[1, "LGA Name"]
        lga2cluster[lga] = cluster
    end
    lga2cluster
end

################################################################################
# Script

indir = "C:\\projects\\data\\dhhs\\demographics\\input"
data  = DataFrame(CSV.File(joinpath(indir, "health_service_clusters.tsv"); delim='\t'))
data  = data[:, ["LGA Name", "COVID Region Cluster"]]
lga2cluster = lga_to_cluster(data)  # Dict: lga => cluster
result  = DataFrame(lga_name=[k for (k,v) in lga2cluster], cluster_name=[v for (k,v) in lga2cluster])
outfile = "C:\\projects\\data\\dhhs\\demographics\\output\\LGA_to_cluster.tsv"
CSV.write(outfile, result; delim='\t')