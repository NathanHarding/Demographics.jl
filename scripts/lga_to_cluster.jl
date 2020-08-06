#=
  Content: Map each LGA to a health service cluster.

  Note:
  Some Melbourne has elements of 4 health service clusters, and
  14 other LGAs have elements of 2 heallth service clusters. In these
  cases we count the number of services within each cluster for the LGA and
  choose the cluster that contains the most services.
  Not precise but probably as close as we can get unless we get lat-lon per service and map these to SA2.  
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