# Collaborative Filtering implementation using SVD (Singular Value Decomposition)
#   Customer prdocut rating matrix is decomposed using SVD
#   Largest eigenvalues and corresponding eigenvectors are taken to simplify customer-product relationship
#   Similar customers are found based on the simplified representation
#   Products purchased by most similar customers but not purchased by given customer are recommended

# code
struct CollFilteringSVD <: CollFiltering

    # to elaborate later
    x

end

# implement contract of Recommender abstract type
"""
    function fit(recommender::CollFilteringSVD, agrs...; kwargs...) 

Fits data to create model that generates product recommendations.

recommnder:     CollFilteringSVD type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function fit(recommender::CollFilteringSVD, agrs...; kwargs...) 

    println("fit method defined in the concrete type")

end

"""
    function predict(recommender::CollFilteringSVD, agrs...; kwargs...)::Vector{CustomerProductRecommendation} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function predict(recommender::CollFilteringSVD, agrs...; kwargs...)::Vector{CustomerProductReco}

    return([("Customer", "Product", "CF SVD", 1)])

end

# implement contract of CollFiltering abstract type
"""
    function similar_customers(cf::CollFilteringSVD, agrs...; kwargs...)::Vector{Customer}

Returns vector of customers similar to a given customer

cf:         CollFilteringSVD type object
agrs:       Tuple of variable number of arguments
kwargs:     Tuple of variable number of keyword arguments 
"""

function similar_customers(cf::CollFilteringSVD, agrs...; kwargs...)::Vector{Customer}

    return([(1)])

end
