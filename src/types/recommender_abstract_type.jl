# abstract Recommender type
# specifil families of algorithms will implement concrete types based on this abstract type
abstract type Recommender end

# contract for the abstract Recommender type
"""
    function fit(recommender::Recommender, agrs...; kwargs...) 

Fits customer product rating data to create recommendation engine.

recommnder:     A recommender type that implements a family of recommendation algorithms like Collaborative Filtering
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function fit(recommender::Recommender, agrs...; kwargs...) 

    error("fit method not defined in the concrete type")

end

"""
    function predict(recommender::Recommender, agrs...; kwargs...)::Vector{CustomerProductRecommendation} 

Returns a vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     A Recommender type that implements a family of recommendation algorithms like Collaborative Filtering
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function predict(recommender::Recommender, agrs...; kwargs...)::Vector{CustomerProductRecommendation}

    error("predict method not defined in the concrete type")

end

