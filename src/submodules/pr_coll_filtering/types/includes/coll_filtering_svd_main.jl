# struct and constructor

mutable struct CollFilteringSVD <: CollFiltering

    # parameters to control logic
    n_max_singular_val::Int64       # max number of singular values to construct approximate ratings matrix
    n_max_similar_cust::Int64       # max number of similar customers to consider when generating recommendations
    n_max_reco_per_cust::Int64       # max number of product recommendations per customer

    # status indicators
    fitted::Bool
    transformed::Bool

    # dummy customer id created in case new transform data is missing fit product
    dummy_customer_id::Union{String, Int64}

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
        function CollFilteringSVD(; n_max_singular_val::Int64=1000, n_max_similar_cust::Int64=20, n_max_reco_per_cust=20)

    Constructor with required keyword arguments with default values.

    n_max_singular_val:    Max number of singular values to keep in SVD
    n_max_similar_cust:    Max number of most similar customers to keep
    n_max_reco_per_cust:   Max number of product recommendations per customer
    """

    function CollFilteringSVD(; n_max_singular_val::Int64=100, n_max_similar_cust::Int64=10, n_max_reco_per_cust=20)
        self = new()
        self.n_max_singular_val = n_max_singular_val
        self.n_max_similar_cust = n_max_similar_cust
        self.n_max_reco_per_cust = n_max_reco_per_cust

        # set status
        self.fitted = false
        self.transformed = false
    
        return self
    end
end
