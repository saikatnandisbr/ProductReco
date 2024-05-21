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

        # reduce rating matrix using SVD
        prod_cust_rating = recommender.U' * recommender.prod_cust_rating        # reduce using SVD

        # similairy calculated based on reduced rating matrix, may be different from that calculated on rating matrix
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

        # products in transform not in fit
        fit_prod_id = keys(recommender.prod_idx_map)                                  # product ids in fit data
        new_prod_id = setdiff(prod_vec, fit_prod_id)                                  # product ids in transform but not in fit data

        # only keep ratings for products that appear in fitted data
        keep_rec = [!in(prod_id, new_prod_id) for prod_id in prod_vec]                # index is false for recrods with new products

        cust_vec = cust_vec[keep_rec]
        prod_vec = prod_vec[keep_rec]
        rating_vec = rating_vec[keep_rec]

        # create dummy customer ratings if any fit product missing in transform products
        missing_prod_id = setdiff(fit_prod_id, prod_vec)
        if !isempty(missing_prod_id)
            dummy_customer_id = (eltype(cust_vec) ==  String ? string(typemax(Int) * rand()) : rand() * typemax(Int))
            recommender.dummy_customer_id = dummy_customer_id   # save in case needede later

            # if dummy customer id exists in real data raise error
            in(dummy_customer_id, cust_vec) && error("Failed to create dummy customer id for missing fit! products")
 
            append!(cust_vec, fill(dummy_customer_id, length(missing_prod_id)))
            append!(prod_vec, missing_prod_id)
            append!(rating_vec, zeros(length(missing_prod_id)))
        end

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

        # reduce rating matrix using SVD
        prod_cust_rating = recommender.U' * prod_cust_rating

        # similairy calculated based on reduced rating matrix, may be different from that calculated on rating matrix
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
