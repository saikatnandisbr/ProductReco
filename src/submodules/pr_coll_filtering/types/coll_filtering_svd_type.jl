# Collaborative Filtering implementation using SVD (Singular Value Decomposition)
#   Customer prdocut rating matrix is decomposed using SVD
#   Largest eigenvalues and corresponding eigenvectors are taken to simplify customer-product relationship
#   Similar customers are found based on comparison of the simplified representation
#   Products purchased by similar customers but not purchased by given customer are recommended

# imports
using SparseArrays      # in standard library
using Random            # in standard library
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

    # customer, product, ratings data
    cust_idx_map::Dict                      # unique customer ids to index of appearance in data
    prod_idx_map::Dict                      # unique product ids to index of appearance in data
    prod_cust_rating::SparseMatrixCSC       # sparse product customer ratings matrix

    # svd output from fit
    U::Matrix{Float64}            
    s::Vector{Float64} 
    V::Matrix{Float64}

    # similar customers from transform
    cust_idx::Vector{Int64}
    similar_cust_idx::Vector{Int64}
    similarity::Vector{Float64}

    """
        function CollFilteringSVD(; n_max_singular_vals::Int64=1000, n_max_similar_custs::Int64=20)

    Constructor with required keyword arguments with default values.

    n_max_singular_vals:    Max number of singular values to keep in SVD
    n_max_similar_custs:    Max number of most similar customers to keep
    """

    function CollFilteringSVD(; n_max_singular_vals::Int64=100, n_max_similar_custs::Int64=10)
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

        # get fields from data
        cust_vec = id.(getfield.(data, 1))
        prod_vec = id.(getfield.(data, 2))
        rating_vec = val.(getfield.(data, 3))

        # id to index map
        cust_idx_map = id_to_index_map(cust_vec)
        recommender.cust_idx_map = cust_idx_map

        prod_idx_map = id_to_index_map(prod_vec)
        recommender.prod_idx_map = prod_idx_map

        # sparse ratings matrix
        idx_customer = [cust_idx_map[id] for id in cust_vec]
        idx_product = [prod_idx_map[id] for id in prod_vec]

        prod_cust_rating = sparse(idx_product, idx_customer, rating_vec)
        recommender.prod_cust_rating = prod_cust_rating

        # truncated SVD   
        n_singular_vals = min(length(cust_idx_map), length(prod_idx_map), recommender.n_max_singular_vals)

        seed = 123
        Random.seed!(seed)

        U, s, V = tsvd(recommender.prod_cust_rating, n_singular_vals)        
        recommender.U, recommender.s, recommender.V = U, s, V

        # set status
        recommender.fitted = true

        return recommender

    catch err
        println("ProductReco.fit!: $err")
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

        # call routine to find similar customers
        prod_cust_rating = recommender.U' * recommender.prod_cust_rating        # reduce using SVD
        cust_idx, similar_cust_idx, similarity = top_similar_customers_threaded(cosine_vec, recommender.n_max_similar_custs, prod_cust_rating)

        # save similar customers
        recommender.cust_idx = cust_idx
        recommender.similar_cust_idx = similar_cust_idx
        recommender.similarity = similarity

        # set status
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.transform!: $err")
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

        # get fields from data
        cust_vec = id.(getfield.(data, 1))
        prod_vec = id.(getfield.(data, 2))
        rating_vec = val.(getfield.(data, 3))

        # only keep ratings for products that appear in fitted data
        fit_prod_ids = keys(recommender.prod_idx_map)                                                       # product ids in fit data
        transform_prod_ids = unique(prod_vec)                                                               # product ids in transform data

        new_prod_ids = transform_prod_ids[[!in(prod_id, fit_prod_ids) for prod_id in transform_prod_ids]]   # product ids in transform but not in fit data

        keep = [!in(prod_id, new_prod_ids) for prod_id in prod_vec]                                         # index is false for recrods with new products

        cust_vec = cust_vec[keep]            # keep entries for fit products only
        prod_vec = prod_vec[keep]            # keep entries for fit products only
        rating_vec = rating_vec[keep]        # keep entries for fit products only

        # id to index map for customers
        cust_idx_map = id_to_index_map(cust_vec)
        recommender.cust_idx_map = cust_idx_map

        # id to index map for products is same as fit
        prod_idx_map = recommender.prod_idx_map

        # sparse ratings matrix
        idx_customer = [cust_idx_map[id] for id in cust_vec]
        idx_product = [prod_idx_map[id] for id in prod_vec]

        prod_cust_rating = sparse(idx_product, idx_customer, rating_vec)
        recommender.prod_cust_rating = prod_cust_rating

        # call routine to find similar customers
        prod_cust_rating = recommender.U' * prod_cust_rating        # reduce using SVD
        cust_idx, similar_cust_idx, similarity = top_similar_customers_threaded(cosine_vec, recommender.n_max_similar_custs, prod_cust_rating)

        # save similar customers
        recommender.cust_idx = cust_idx
        recommender.similar_cust_idx = similar_cust_idx
        recommender.similarity = similarity

        # set status
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.transform!: $err")
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
        println("ProductReco.fit_transform!: $err")
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

function PRCollFiltering.similar_customers(cf::CollFilteringSVD, cust::Customer)::Vector{SimilarCustomer}

    !ProductReco.istransformed(cf) && error("Recommender not transformed, cannot return similar customers")

    cust_id = id(cust)                              # customer id
    cust_idx = cf.cust_idx_map[cust_id]             # customer index in sparse array

    # similar customer index
    similar_cust_idx = cf.similar_cust_idx[cf.cust_idx .== cust_idx]
    similarity = cf.similarity[cf.cust_idx .== cust_idx]      

    # reverse lookup customer id from customer index
    similar_cust_id = [key for (key, val) in cf.cust_idx_map if val ∈ similar_cust_idx]

    # map customer constructor over ids
    customer = map(Customer, similar_cust_id)

    similar_customer = [(customer[i], similarity[i]) for i in 1:length(customer)]

    return similar_customer
end
