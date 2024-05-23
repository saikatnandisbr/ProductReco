# abstract Collaborative Filtering type
# subtype of Recommender
# generates product recommendations using Collaborative Filtering

# exports

# code
abstract type CollFiltering <: Recommender end

# contract
"""
    function similar_customers(cf::CollFiltering, agrs...; kwargs...)::Vector{SimilarCustomer}

Return vector of customers similar to a given customer.

cf:         CollFiltering type object
agrs:       Tuple of variable number of arguments
kwargs:     Tuple of variable number of keyword arguments 
"""

function similar_customers(cf::CollFiltering, agrs...; kwargs...)::Vector{SimilarCustomer}

    error("similar_customers method not defined in the concrete type")

end