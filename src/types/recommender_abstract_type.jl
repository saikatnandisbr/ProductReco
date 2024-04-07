# general Recommender abstract type
# specifil families of algorithms will implement concrete types based on this abstract type
abstract type Recommender end

# contract for the abstract Recommender type
"""
    function fit(recommender::Recommender, data::Vector{CustomerProductRating}) 

Fits customer product rating data to create recommendation engine.

recommnder:     A recommender type that implements a family of recommendation algorithms like Collaborative Filtering
data:           Vector of customer product rating (::CustomerProductRating)
"""

function fit(recommender::Recommender, data::Vector{CustomerProductRating}) 

    error("fit method not defined in the concrete type")

end

"""
    function predict(recommender::Recommender, data::Vector{String})::Vector{CustomerProductRecommendation} 

Returns a vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     A Recommender type that implements a family of recommendation algorithms like Collaborative Filtering
data:           Vector of customers

"""

function predict(recommender::Recommender, data::Vector{String})::Vector{CustomerProductRecommendation}

    error("predict method not defined in the concrete type")

end

