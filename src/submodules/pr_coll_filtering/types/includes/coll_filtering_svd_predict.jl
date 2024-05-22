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
    maxlen_pr = length(predict_cust_idx) * recommender.n_max_reco_per_cust     # max length of vector in tuple
    prod_reco = Tuple((Vector{Int64}(undef, maxlen_pr), Vector{Int64}(undef, maxlen_pr), Vector{Float64}(undef, maxlen_pr)))
    curr_loc_prod_reco = 1                                                      # location to write next

    # accumulate product recommendations for given customer
    # (prod_idx, raw score)
    maxlen_cpr = length(recommender.prod_idx_map)                               # max length of vector in tuple
    cust_prod_reco = Tuple((Vector{Int64}(undef, maxlen_cpr), Vector{Float64}(undef, maxlen_cpr)))
    curr_loc_cust_prod_reco = 1                                                 # location to write next

    # accumulate ratings of products of similar customers
    # (similar_cust_idx, similarity, prod_idx, prod_rating)
    maxlen_scspr = length(recommender.n_max_similar_cust) * length(recommender.prod_idx_map)  # max length of vector in tuple
    similar_cust_sim_prod_rating = Tuple((Vector{Int64}(undef, maxlen_scspr), Vector{Float64}(undef, maxlen_scspr), Vector{Int64}(undef, maxlen_scspr), Vector{Float64}(undef, maxlen_scspr)))
    curr_loc_similar_cust_sim_prod_rating = 1                                                 # location to write next

    # loop through predict customers
    for (i, curr_predict_cust_idx) in enumerate(predict_cust_idx)

        # products of predict customer
        predict_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_predict_cust_idx])[1]

        # similar customers and similarity
        similar_cust_slice = recommender.cust_idx .== curr_predict_cust_idx
        similar_cust_idx = @view recommender.similar_cust_idx[similar_cust_slice]
        similarity =       @view recommender.similarity[similar_cust_slice]

        # loop through similar customers
        for (j, curr_similar_cust_idx) in enumerate(similar_cust_idx)
            
            similar_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[1]
            similar_cust_prod_rating = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[2]

            # loop throught products of similar customers
            for (k, curr_similar_cust_prod_idx) in enumerate(similar_cust_prod_idx)

                getfield(similar_cust_sim_prod_rating, 1)[curr_loc_similar_cust_sim_prod_rating] = curr_similar_cust_idx
                getfield(similar_cust_sim_prod_rating, 2)[curr_loc_similar_cust_sim_prod_rating] = similarity[j]
                getfield(similar_cust_sim_prod_rating, 3)[curr_loc_similar_cust_sim_prod_rating] = curr_similar_cust_prod_idx
                getfield(similar_cust_sim_prod_rating, 4)[curr_loc_similar_cust_sim_prod_rating] = similar_cust_prod_rating[k]

                curr_loc_similar_cust_sim_prod_rating += 1      # advance current location in accumulator

            end  # end loop for products of similar customers
            
        end  # end loop for similar customers 

        # calculate score for each product for predict customer
        for curr_prod_idx in unique(@view getfield(similar_cust_sim_prod_rating, 3)[1:curr_loc_similar_cust_sim_prod_rating-1])

            # omit product aleady existing for predict customer
            curr_prod_idx in predict_cust_prod_idx && continue

            # slice similar customer similarity rating records by product
            prod_slice = (@view getfield(similar_cust_sim_prod_rating, 3)[1:curr_loc_similar_cust_sim_prod_rating-1]) .== curr_prod_idx         

            # get customer similarity and customer rating for the product
            similarity = @view (@view getfield(similar_cust_sim_prod_rating, 2)[1:curr_loc_similar_cust_sim_prod_rating-1])[prod_slice]
            rating = @view (@view getfield(similar_cust_sim_prod_rating, 4)[1:curr_loc_similar_cust_sim_prod_rating-1])[prod_slice]

            score = round(fn_score(Ref(similarity), Ref(rating)), digits=4)

            # append to accumulators
            getfield(cust_prod_reco, 1)[curr_loc_cust_prod_reco] = curr_prod_idx      # prod index
            getfield(cust_prod_reco, 2)[curr_loc_cust_prod_reco] = score              # raw score

            curr_loc_cust_prod_reco += 1                                              # update current location in accumulator

        end  # end loop calculate score for each product for predict customer

        # recommeneded proucts with highest scores for predict customer
        n_reco = min(recommender.n_max_reco_per_cust, curr_loc_cust_prod_reco-1)                # number of recommendations for predict customer
        
        sort_seq = sortperm(getfield(cust_prod_reco, 2)[1:curr_loc_cust_prod_reco-1], rev=true)                         # sort by score descending
        
        reco_prod_idx = @view (@view (@view getfield(cust_prod_reco, 1)[1:curr_loc_cust_prod_reco-1])[sort_seq])[1:n_reco]      # top scores
        reco_score =    @view (@view (@view getfield(cust_prod_reco, 2)[1:curr_loc_cust_prod_reco-1])[sort_seq])[1:n_reco]      # top scores

        # add to accumulators
        getfield(prod_reco, 1)[curr_loc_prod_reco:curr_loc_prod_reco+n_reco-1] .= curr_predict_cust_idx   # predict customer
        getfield(prod_reco, 2)[curr_loc_prod_reco:curr_loc_prod_reco+n_reco-1] = reco_prod_idx            # recommended product
        getfield(prod_reco, 3)[curr_loc_prod_reco:curr_loc_prod_reco+n_reco-1] = reco_score               # raw score

        curr_loc_prod_reco += n_reco    # update current location in accumulator
    
        # clear accumulators
        curr_loc_similar_cust_sim_prod_rating = 1
        curr_loc_cust_prod_reco = 1

    end  # end loop for predict customers

    # convert raw score to relative score
    # if only one product then percentile rank cannot be calculated
    if curr_loc_prod_reco <= 2
        relative_reco_score = fill(100, n_curr_loc_prod_reco-1)
    else
        raw_score = @view getfield(prod_reco, 3)[1:curr_loc_prod_reco-1]                # raw scores across all generated recommendations
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]   # relative scores across all generated recommendations
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in (@view getfield(prod_reco, 1)[1:curr_loc_prod_reco-1])]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in (@view getfield(prod_reco, 2)[1:curr_loc_prod_reco-1])]

    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
