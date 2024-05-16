# Collaborative Filtering implementation using SVD (Singular Value Decomposition)
#   Customer prdocut rating matrix is decomposed using SVD
#   Largest eigenvalues and corresponding eigenvectors are taken to simplify customer-product relationship
#   Similar customers are found based on comparison of the simplified representation
#   Products purchased by similar customers but not purchased by given customer are recommended

# imports
using SparseArrays
using Random
using TSVD

# exports

# code
mutable struct CollFilteringSVD <: CollFiltering

    # parameters to control logic
    n_max_singular_vals::Int64       # max number of singular values to construct approximate ratings matrix
    n_max_similar_custs::Int64         # max number of similar customers to consider when generating recommendations

    # status indicators
    fitted::Bool
    transformed::Bool

    # fit data
    cust_idx_map_fit::Dict                      # unique customer ids to index of appearance in data
    prod_idx_map_fit::Dict                      # unique product ids to index of appearance in data
    cust_prod_ratings_fit::SparseMatrixCSC      # sparse customer product ratings matrix

    # transform data
    cust_idx_map_transform::Dict                      # unique customer ids to index of appearance in data
    prod_idx_map_transform::Dict                      # unique product ids to index of appearance in data
    cust_prod_ratings_transform::SparseMatrixCSC      # sparse customer product ratings matrix

    # svd output
    U::Matrix{Float64}            
    s::Vector{Float64} 
    V::Matrix{Float64}

    """
        function CollFilteringSVD(; n_max_singular_vals::Int64=1000, n_max_similar_custs::Int64=20)

    Constructor with required keyword arguments with default values.

    n_max_singular_vals:    Max number of singular values to keep in SVD
    n_max_similar_custs:    Max number of most similar customers to keep
    """

    function CollFilteringSVD(; n_max_singular_vals::Int64=1000, n_max_similar_custs::Int64=20)
        self = new()
        self.n_max_singular_vals = n_max_singular_vals
        self.n_max_similar_custs = n_max_similar_custs

        # set status
        self.fitted = false
        self.transformed = false

        return self
    end
end

# implement contract of Recommender abstract type
"""
    function roductReco.isfitted(recommender::CollFilteringSVD)::Bool

Accessor function to get fitted status.

recommender:    Recommender type opbject
"""

function ProductReco.isfitted(recommender::CollFilteringSVD)::Bool

    return recommender.fitted

end

"""
    function ProductReco.istransformed(recommender::CollFilteringSVD)::Bool

Accessor function to get transformed status.

recommender:    Recommender type opbject
"""

function ProductReco.istransformed(recommender::CollFilteringSVD)::Bool

    return recommender.transformed

end

"""
    function ProductReco.fit!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

Fits data to create model that generates product recommendations.

recommnder:     CollFilteringSVD type object
data:           Vector of customer product rating type (CustomerProductRating)
"""

function ProductReco.fit!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

    try
        # set status
        recommender.fitted = false

        # id to index map
        all_customers = id.(getfield.(data, 1))
        cust_idx_map = id_to_index_map(all_customers)
        recommender.cust_idx_map_fit = cust_idx_map

        all_products = id.(getfield.(data, 2))
        prod_idx_map = id_to_index_map(all_products)
        recommender.prod_idx_map_fit = prod_idx_map

        # sparse ratings matrix
        idx_customers = [cust_idx_map[id] for id in all_customers]
        idx_products = [prod_idx_map[id] for id in all_products]

        cust_prod_ratings = sparse(idx_customers, idx_products, val.(getfield.(data, 3)))
        recommender.cust_prod_ratings_fit = cust_prod_ratings

        # truncated SVD   
        n_singular_vals = min(length(cust_idx_map), length(prod_idx_map), recommender.n_max_singular_vals)

        seed = 123
        Random.seed!(seed)

        U, s, V = tsvd(recommender.cust_prod_ratings_fit, n_singular_vals)        
        recommender.U, recommender.s, recommender.V = U, s, V

        # set status
        recommender.fitted = true

        return recommender

    catch err
        println("ProductReco.fit! error: $err")
        throw(error())
    end

end

"""
    function ProductReco.transform!(recommender::CollFilteringSVD)::CollFilteringSVD

Transforms data used to fit model with fitted model.

recommnder:     CollFilteringSVD type object
"""

function ProductReco.transform!(recommender::CollFilteringSVD)::CollFilteringSVD

    try
        # set status
        recommender.transformed = false

        # copy fit data to transformed
        recommender.cust_idx_map_transform = recommender.cust_idx_map_fit
        recommender.prod_idx_map_transform = recommender.prod_idx_map_fit
        recommender.cust_prod_ratings_transform = recommender.cust_prod_ratings_fit

        # call routine to find similar customers

        # set status
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.transform! error: $err")
        throw(error())
    end
end

"""
    function ProductReco.transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

Transforms new data with fitted model.

recommnder:     CollFilteringSVD type object
data:           Vector of customer product rating type (CustomerProductRating)

"""

function ProductReco.transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

    try
        # set status
        recommender.transformed = false

        # id to index map
        all_customers = id.(getfield.(data, 1))
        cust_idx_map = id_to_index_map(all_customers)
        recommender.cust_idx_map_transform = cust_idx_map

        all_products = id.(getfield.(data, 2))
        prod_idx_map = id_to_index_map(all_products)
        recommender.prod_idx_map_transform = prod_idx_map

        # sparse ratings matrix
        idx_customers = [cust_idx_map[id] for id in all_customers]
        idx_products = [prod_idx_map[id] for id in all_products]

        cust_prod_ratings = sparse(idx_customers, idx_products, val.(getfield.(data, 3)))
        recommender.cust_prod_ratings_transform = cust_prod_ratings

        # call routine to find similar customers

        # set status
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.transform! error: $err")
        throw(error())
    end
end

"""
    function ProductReco.fit_transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

Fit model with data and transform the same data with fitted model.

recommnder:     CollFilteringSVD type object
data:           Vector of customer product rating type (CustomerProductRating)
"""

function ProductReco.fit_transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

    try

        # set status
        recommender.fitted = false
        recommender.transformed = false

        recommender = (ProductReco.transform! ∘ ProductReco.fit!)(recommender, data)

        # set status
        recommender.fitted = true
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.transform! error: $err")
        throw(error())
    end
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
