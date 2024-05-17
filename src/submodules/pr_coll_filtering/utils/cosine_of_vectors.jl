# cosine of angle between vectors

# imports
using LinearAlgebra    # in standard library

"""
    function cosine_vec(vec1::Vector{Float64}, vec2::Vector{Float64})::Float64

Returns cosine of angle between two vectors.
If two vectors not of same size DimensionMismatch exception will be raised.
Exception handing not added inside function for performance.

vec1:       First vector
vec2:       Second vector
"""

function cosine_vec(vec1::Vector{Float64}, vec2::Vector{Float64})::Float64

    return dot(vec1, vec2) / (norm(vec1) * norm(vec2))        

end
