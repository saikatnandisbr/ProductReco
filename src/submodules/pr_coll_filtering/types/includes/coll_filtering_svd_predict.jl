"""
    function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
customer:       Customers for whom recommendations to be predicted 
fn_score:       Function to calculate recommendation score using vectors of similarity and rating
"""

function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 

    !ProductReco.istransformed(recommender) && error("ProductReco.predict: Recommender not transformed, cannot continue")

    # customer id
    predict_cust_id = id.(customer)

    # customer index
    try
        predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]       
    catch err
        println("ProductReco.predict: Customer not present in transformed data, cannot continue")
        error(err)
    end

    # proceed if no error - calculate again as try block above has own scope   
    predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]

    # accumulate product recommendations
    # (cust_idx, prod_idx, raw score)
    prod_reco = Tuple((Vector{Int64}(), Vector{Int64}(), Vector{Float64}()))

    # accumulate product recommendations for given customer
    # (prod_idx, raw score)
    cust_prod_reco = Tuple((Vector{Int64}(), Vector{Float64}()))

    # accumulate ratings of products of similar customers
    # (similar_cust_idx, similarity, prod_idx, prod_rating)
    similar_cust_similarity_prod_rating = Tuple((Vector{Int64}(), Vector{Float64}(), Vector{Int64}(), Vector{Float64}()))
  
    # loop through predict customers
    for (i, curr_predict_cust_idx) in enumerate(predict_cust_idx)

        # products of predict customer
        predict_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_predict_cust_idx])[1]

        # similar customers and similarity
        similar_cust_slice = recommender.cust_idx .== curr_predict_cust_idx
        similar_cust_idx = view(recommender.similar_cust_idx, similar_cust_slice)
        similarity = view(recommender.similarity, similar_cust_slice)

        # loop through similar customers
        for (j, curr_similar_cust_idx) in enumerate(similar_cust_idx)
            
            similar_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[1]
            similar_cust_prod_rating = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[2]

            # loop throught products of similar customers
            for (k, curr_similar_cust_prod_idx) in enumerate(similar_cust_prod_idx)

                push!(getfield(similar_cust_similarity_prod_rating, 1), curr_similar_cust_idx)
                push!(getfield(similar_cust_similarity_prod_rating, 2), similarity[j])
                push!(getfield(similar_cust_similarity_prod_rating, 3), curr_similar_cust_prod_idx)
                push!(getfield(similar_cust_similarity_prod_rating, 4), similar_cust_prod_rating[k])

            end  # end loop for products of similar customers
            
        end  # end loop for similar customers 

        # calculate score for each product for predict customer
        for curr_prod_idx in unique(getfield(similar_cust_similarity_prod_rating, 3))

            # omit product aleady existing for predict customer
            curr_prod_idx in predict_cust_prod_idx && continue

            prod_slice = getfield(similar_cust_similarity_prod_rating, 3) .== curr_prod_idx
            similarity = view(getfield(similar_cust_similarity_prod_rating, 2), prod_slice)
            rating = view(getfield(similar_cust_similarity_prod_rating, 4), prod_slice)

            score = round(fn_score(Ref(similarity), Ref(rating)), digits=4)

            append!(getfield(cust_prod_reco, 1), curr_prod_idx)                          # prod index
            append!(getfield(cust_prod_reco, 2), score)                                  # raw score
    
        end  # end loop calculate score for each product for predict customer

        # recommeneded proucts with highest scores for predict customer
        n_reco = min(recommender.n_max_reco_per_cust, length(getfield(cust_prod_reco, 1)))      # number of recommendations for predict customer
        
        sort_seq = sortperm(getfield(cust_prod_reco, 2), rev=true)                              # to sort recommendations by score descending
        
        reco_prod_idx = view(view(getfield(cust_prod_reco, 1), sort_seq), 1:n_reco)             # top products
        reco_score = view(view(getfield(cust_prod_reco, 2), sort_seq), 1:n_reco)                # top scores

        # recommendations for current predict customer
        append!(getfield(prod_reco, 1), fill(curr_predict_cust_idx, n_reco))    # append current predict cust index
        append!(getfield(prod_reco, 2), reco_prod_idx)                          # recommended prod index
        append!(getfield(prod_reco, 3), reco_score)                             # raw reco score
    
        # clear accumulators
        for f in eachindex(similar_cust_similarity_prod_rating)
            resize!(getfield(similar_cust_similarity_prod_rating, f), 0)
        end
        
        for f in eachindex(cust_prod_reco)
            resize!(getfield(cust_prod_reco, f), 0)
        end

    end  # end loop for predict customers

    # convert raw score to relative score
    # if only one product then percentile rank cannot be calculated
    if length(getfield(prod_reco, 1)) == 1
        relative_reco_score = [100]
    else
        raw_score = getfield(prod_reco, 3)  # raw scores across all generated recommendations
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in getfield(prod_reco, 1)]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in getfield(prod_reco, 2)]

    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
