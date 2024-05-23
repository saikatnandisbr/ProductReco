
"""
    function ProductReco.fit!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

Fit data to create model that generates product recommendations.

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
        n_singular_val = min(length(cust_idx_map), length(prod_idx_map), recommender.n_max_singular_val)

        seed = 123
        Random.seed!(seed)

        U, s, V = tsvd(recommender.prod_cust_rating, n_singular_val)        
        recommender.U, recommender.s, recommender.V = U, s, V

        # set status
        recommender.fitted = true

        return recommender

    catch err
        println("ProductReco.fit!: $err")
        throw(error())
    end

end
