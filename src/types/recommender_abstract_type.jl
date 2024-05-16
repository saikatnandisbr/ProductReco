# abstract Recommender type
# represents a generator of product recommendations

# exports
export Recommender

# code
abstract type Recommender end

# contract
"""
    function fit!(recommender::Recommender, agrs...; kwargs...)::Recommender 

Fits data to create model that generates product recommendations.
Returns the fitted Recommender object.

recommnder:     Recommender type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function fit!(recommender::Recommender, agrs...; kwargs...)::Recommender

    error("fit! method not defined in the concrete type")

end

"""
    function transform!(recommender::Recommender, agrs...; kwargs...)::Recommender 

Transforms data, potentially new, using fitted model.
Returns the transformed Recommender object.

recommnder:     Recommender type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function transform!(recommender::Recommender, agrs...; kwargs...)::Recommender

    error("transform! method not defined in the concrete type")

end


"""
    function predict(recommender::Recommender, agrs...; kwargs...)::Vector{CustomerProductRecommendation} 

Returns vector of customer product recommendations.

recommnder:     Recommender type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function predict(recommender::Recommender, agrs...; kwargs...)::Vector{CustomerProductReco}

    error("predict method not defined in the concrete type")

end
