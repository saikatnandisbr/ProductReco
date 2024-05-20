# cosine of angle between vectors

# imports
using LinearAlgebra     # in standard library

"""
    function cosine_vec(vec1::T, vec2::T)::Float64 where {T <: AbstractVector}

Returns cosine of angle between two vectors.
If two vectors not of same size DimensionMismatch exception will be raised.

vec1:       First vector
vec2:       Second vector
"""

function cosine_vec(vec1::T, vec2::T)::Float64 where {T <: AbstractVector}

    sim_score =  dot(vec1, vec2) / (norm(vec1) * norm(vec2))        

    return round(sim_score, digits=4)
end
