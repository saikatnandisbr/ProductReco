# two methods - one to transform existing data in recommender, another to transform new data

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
        cust_idx, similar_cust_idx, similarity = top_similar_customers_threaded(cosine_vec, recommender.n_max_similar_cust, prod_cust_rating)

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
        cust_idx, similar_cust_idx, similarity = top_similar_customers_threaded(cosine_vec, recommender.n_max_similar_cust, prod_cust_rating)

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
