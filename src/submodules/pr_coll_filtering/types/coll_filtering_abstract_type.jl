# abstract Collaborative Filtering type
# subtype of Recommender
# generates product recommendations using Collaborative Filtering

# exports
export similar_customers

# code
abstract type CollFiltering <: Recommender end

# contract
"""
    function similar_customers(cf::CollFiltering, agrs...; kwargs...)::Vector{Customer}

Returns vector of customers similar to a given customer

cf:         CollFiltering type object
agrs:       Tuple of variable number of arguments
kwargs:     Tuple of variable number of keyword arguments 
"""

function similar_customers(cf::CollFiltering, agrs...; kwargs...)::Vector{Customer}

    error("similar_customers method not defined in the concrete type")

end