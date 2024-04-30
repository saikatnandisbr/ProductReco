# abstract Recommender type
# represents a generator of product recommendations
abstract type Recommender end

# contract

"""
    function params(recommender::Recommender)::Dict

Accessor function to get parameters used in contructor of the recommender. 
Returns dictionary of constructor parameters.

recommnder:     Recommender type object
"""

function params(recommender::Recommender)::Dict

    error("params method not defined in the concrete type")

end

"""
    function isfitted(recommender::Recommender)::Boolean

Accessor function to inquire if the recommender has been fitted or not. 

recommnder:     Recommender type object
"""

function isfitted(recommender::Recommender)::Boolean

    error("isfitted method not defined in the concrete type")

end

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
