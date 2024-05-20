"""
    function predict(recommender::CollFilteringSVD, customers::Vector{Customer})::Vector{CustomerProductReco} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function ProductReco.predict(recommender::CollFilteringSVD, customers::Vector{Customer})::Vector{CustomerProductReco}

    cust_id = id.(customers)
    cust_idx = [recommender.cust_idx_map[id] for id in cust_id]

    # gather products ratings of similar customers
    # (cust_idx, similar_cust_idx, similarity, prod_idx, prod_rating)
    cust_similar_cust_prod_rating = Vector{Tuple{Int64, Int64, Float64, Int64, Float64}}()

    # loop through predict customers
    for i in 1:length(cust_idx)

        # products rated by prediction customer
        predict_cust_prod_idx = findnz(recommender.prod_cust_rating[:, cust_idx[i]])[1]

        # similar customers and similarity
        similar_cust_slice = recommender.cust_idx .== cust_idx[i]
        similar_cust_idx = recommender.similar_cust_idx[similar_cust_slice]
        similarity = recommender.similarity[similar_cust_slice]

        # loop through similar customers
        for j in 1:length(similar_cust_idx)
            
            similar_cust_prod_idx = findnz(recommender.prod_cust_rating[:, similar_cust_idx[j]])[1]
            similar_cust_prod_rating = findnz(recommender.prod_cust_rating[:, similar_cust_idx[j]])[2]

            # loop throught products of similar customers
            for k in 1:length(similar_cust_prod_idx)

                push!(
                    cust_similar_cust_prod_rating, 
                    (cust_idx[i], similar_cust_idx[j], similarity[j], similar_cust_prod_idx[k], similar_cust_prod_rating[k])
                )

            end  # end loop for products of similar customers
            
        end  # end loop for similar customers 

    end  # end loop for predict customers


    return([("A Customer", "A Product", 1)])
end
