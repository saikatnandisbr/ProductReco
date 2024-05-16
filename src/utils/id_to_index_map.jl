# prepare dict of values and unique indices

# imports

# exports
export id_to_index_map
 
"""
    function id_to_index_map(vec::Vector{T})::Dict where {T <: Union{Int64, String}}}

Returns dictionary with unique ID values and integer indicies based on order of occurrence.

vec:        Vector of values which are integer or string IDs  
"""
function id_to_index_map(vec::Vector{T})::Dict where {T <: Union{Int64, String}}

    unique_ids = unique(vec)
    id_to_index_map = Dict(unique_ids .=> 1:length(unique_ids))

    return id_to_index_map

end
