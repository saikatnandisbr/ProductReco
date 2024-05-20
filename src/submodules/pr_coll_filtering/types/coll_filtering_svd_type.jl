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

# includes
include("includes/coll_filtering_svd_main.jl")          # struct and constructor
include("includes/coll_filtering_svd_accessors.jl")     # accessors defined in Recommender abstract type
include("includes/coll_filtering_svd_fit.jl")           # fit! from Recommender abstract type
include("includes/coll_filtering_svd_transform.jl")     # transform! method from Recommender abstract type - two methods
include("includes/coll_filtering_svd_fit_transform.jl") # fit_transform! method from Recommender abstract type
include("includes/coll_filtering_svd_predict.jl")       # predict from Recommender abstract type
include("includes/coll_filtering_svd_similar_customers.jl")  # similar_customers method from Coll Filtering abstract type

# code