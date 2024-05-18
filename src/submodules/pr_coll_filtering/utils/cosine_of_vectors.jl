# cosine of angle between vectors

# imports
using SparseArrays      # in standard library
using LinearAlgebra     # in standard library

"""
    function cosine_vec(vec1::T, vec2::T)::Float64 where {T <: Union{Vector{Float64}, SparseVector}}

Returns cosine of angle between two vectors.
If two vectors not of same size DimensionMismatch exception will be raised.
Exception handing not added inside function for performance.

vec1:       First vector
vec2:       Second vector
"""

function cosine_vec(vec1::T, vec2::T)::Float64 where {T <: Union{Vector{Float64}, SparseVector}}

    return dot(vec1, vec2) / (norm(vec1) * norm(vec2))        

end
