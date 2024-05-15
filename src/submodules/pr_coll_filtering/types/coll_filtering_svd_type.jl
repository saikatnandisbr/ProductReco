# Collaborative Filtering implementation using SVD (Singular Value Decomposition)
#   Customer prdocut rating matrix is decomposed using SVD
#   Largest eigenvalues and corresponding eigenvectors are taken to simplify customer-product relationship
#   Similar customers are found based on comparison of the simplified representation
#   Products purchased by similar customers but not purchased by given customer are recommended

# imports
import Base.@kwdef
using SparseArrays
using Random
using TSVD

# exports

# code
@kwdef mutable struct CollFilteringSVD <: CollFiltering

    # parameters to control logic
    n_max_singular_vals::Int64 = 1000       # max number of singular values to construct approximate ratings matrix
    n_max_similar_custs::Int64 = 50         # max number of similar customers to consider when generating recommendations

    # id to index map
    cust_idx_map = Dict()
    prod_idx_map = Dict()

    # ratings data in sparse matrix
    cust_prod_ratings = spzeros(1,1)     # initialize

    # svd output
    U = zeros(1, 1)                      # initialize
    s = zeros(1)                         # initialize
    V = zeros(1, 1)                      # initialize
end

# implement contract of Recommender abstract type
"""
    function fit(recommender::CollFilteringSVD, agrs...; kwargs...) 

Fits data to create model that generates product recommendations.

recommnder:     CollFilteringSVD type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function ProductReco.fit!(recommender::CollFilteringSVD; data::Vector{CustomerProductRating}) 

    seed = 123
    Random.seed!(seed)

    try
        # id to index map
        all_customers = id.(getfield.(data, 1))
        unique_customers = unique(all_customers)
        cust_idx_map = Dict(unique_customers .=> 1:length(unique_customers))
        recommender.cust_idx_map = cust_idx_map

        all_products = id.(getfield.(data, 2))
        unique_products = unique(all_products)
        prod_idx_map = Dict(unique_products .=> 1:length(unique_products))
        recommender.prod_idx_map = prod_idx_map

        # sparse ratings matrix
        idx_customers = [cust_idx_map[id] for id in all_customers]
        idx_products = [prod_idx_map[id] for id in all_products]

        cust_prod_ratings = sparse(idx_customers, idx_products, val.(getfield.(data, 3)))
        recommender.cust_prod_ratings = cust_prod_ratings

        # truncated SVD
        n_singular_vals = min(length(unique_customers), length(unique_products), recommender.n_max_singular_vals)
        U, s, V = tsvd(recommender.cust_prod_ratings, n_singular_vals)        
        recommender.U, recommender.s, recommender.V = U, s, V

    catch err
        println("ProductReco.fit! error: $err")
        throw(error())
    end

    return nothing
end

"""
    function predict(recommender::CollFilteringSVD, agrs...; kwargs...)::Vector{CustomerProductReco} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function ProductReco.predict(recommender::CollFilteringSVD, agrs...; kwargs...)::Vector{CustomerProductReco}

    return([("A Customer", "A Product", 1)])

end

# implement contract of CollFiltering abstract type
"""
    function similar_customers(cf::CollFilteringSVD, agrs...; kwargs...)::Vector{Customer}

Returns vector of customers similar to a given customer

cf:         CollFilteringSVD type object
agrs:       Tuple of variable number of arguments
kwargs:     Tuple of variable number of keyword arguments 
"""

function PRCollFiltering.similar_customers(cf::CollFilteringSVD, agrs...; kwargs...)::Vector{Customer}

    return([("Another Customer")])

end
