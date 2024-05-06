# abstract Recommender type
# represents a generator of product recommendations

# exports
export Recommender

# code
abstract type Recommender end

# contract
"""
    function fit(recommender::Recommender, agrs...; kwargs...) 

Fits data to create model that generates product recommendations.

recommnder:     Recommender type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function fit(recommender::Recommender, agrs...; kwargs...) 

    error("fit method not defined in the concrete type")

end

"""
    function predict(recommender::Recommender, agrs...; kwargs...)::Vector{CustomerProductRecommendation} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     Recommender type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function predict(recommender::Recommender, agrs...; kwargs...)::Vector{CustomerProductRecommendation}

    error("predict method not defined in the concrete type")

end
