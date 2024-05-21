# imports
using SparseArrays
using LinearAlgebra
using StatsBase

"""
    function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer})::Vector{CustomerProductReco} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
customer:       Customers for whom recommendations to be predicted 
"""

function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer})::Vector{CustomerProductReco}

    !ProductReco.istransformed(recommender) && error("ProductReco.predict: Recommender not transformed, cannot continue")

    # customer id
    predict_cust_id = id.(customer)

    # customer index
    try
        predict_cust_idx = predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]       
    catch err
        println("ProductReco.predict: Customer not present in transformed data, cannot continue")
        error(err)
    end

    # if no error above, can proceed
    predict_cust_idx = predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]

    # accumulate product recommendations
    # (cust_idx, prod_idx, raw score)
    prod_reco = Vector{Tuple{Int64, Int64, Float64}}()

    # accumulate product recommendations for given customer
    # (prod_idx, raw score)
    cust_prod_reco = Vector{Tuple{Int64, Float64}}()

    # accumulate ratings of products of similar customers
    # (similar_cust_idx, similarity, prod_idx, prod_rating)
    similar_cust_similarity_prod_rating = Vector{Tuple{Int64, Float64, Int64, Float64}}()
   
    # loop through predict customers
    for (i, curr_predict_cust_idx) in enumerate(predict_cust_idx)

        # products of predict customer
        predict_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_predict_cust_idx])[1]

        # similar customers and similarity
        similar_cust_slice = recommender.cust_idx .== curr_predict_cust_idx
        similar_cust_idx = recommender.similar_cust_idx[similar_cust_slice]
        similarity = recommender.similarity[similar_cust_slice]

        # loop through similar customers
        for (j, curr_similar_cust_idx) in enumerate(similar_cust_idx)
            
            similar_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[1]
            similar_cust_prod_rating = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[2]

            # loop throught products of similar customers
            for (k, curr_similar_cust_prod_idx) in enumerate(similar_cust_prod_idx)

                push!(
                    similar_cust_similarity_prod_rating, 
                    (curr_similar_cust_idx, similarity[j], curr_similar_cust_prod_idx, similar_cust_prod_rating[k])
                )

            end  # end loop for products of similar customers
            
        end  # end loop for similar customers 

        # calculate score for each product for predict customer
        for curr_prod_idx in unique(getfield.(similar_cust_similarity_prod_rating, 3))

            # omit product aleady existing for predict customer
            curr_prod_idx in predict_cust_prod_idx && continue

            prod_slice = getfield.(similar_cust_similarity_prod_rating, 3) .== curr_prod_idx
            similarity = getfield.(similar_cust_similarity_prod_rating, 2)[prod_slice]
            rating = getfield.(similar_cust_similarity_prod_rating, 4)[prod_slice]

            score = round(dot(similarity, rating), digits=4)

            push!(cust_prod_reco, (curr_prod_idx, score))
        end  # end loop calculate score for each product for predict customer

        # recommeneded proucts with highest scores for predict customer
        n_reco = min(recommender.n_max_reco_per_cust, length(cust_prod_reco))    # number of recommendations for predict customer
        
        sort_seq = sortperm(getfield.(cust_prod_reco, 2), rev=true)             # to sort recommendations by score descending
        
        reco_prod_idx = getfield.(cust_prod_reco, 1)[sort_seq][1:n_reco]        # top products
        reco_score = getfield.(cust_prod_reco, 2)[sort_seq][1:n_reco]           # top scores

        # recommendations for current predict customer
        append!(prod_reco, collect(zip(fill(curr_predict_cust_idx, n_reco), reco_prod_idx, reco_score)))

        # clear accumulator
        resize!(similar_cust_similarity_prod_rating, 0)
        resize!(cust_prod_reco, 0)

    end  # end loop for predict customers

    # convert raw score to relative score
    # if only one product then percentile rank cannot be calculated
    if length(prod_reco) == 1
        relative_reco_score = [100]
    else
        raw_score = getfield.(prod_reco, 3)  # raw scores across all generated recommendations
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in getfield.(prod_reco, 1)]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in getfield.(prod_reco, 2)]

    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
