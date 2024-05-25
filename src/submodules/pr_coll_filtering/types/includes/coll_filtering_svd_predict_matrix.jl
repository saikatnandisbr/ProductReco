# helper functions used by predict
"""
    function check_error_in_predict_call(recommender::CollFilteringSVD, predict_cust::Vector{Customer})

Raise error if exception conditions exist in agruments to predict.

recommnder:     CollFilteringSVD type object
predict_cust:   Customers for whom recommendations to be predicted 
"""

function check_error_in_predict_call(recommender::CollFilteringSVD, predict_cust::Vector{Customer})

    !ProductReco.istransformed(recommender) && error("ProductReco.predict: Recommender not transformed, cannot continue")

    # check if each customer exists in transformed recommender
    try

        predict_cust_id = id.(predict_cust)
        _ = [recommender.cust_idx_map[id] for id in predict_cust_id]       

    catch err

        println("ProductReco.predict: Customer not present in transformed data, cannot continue")
        error(err)
        
    end

    return nothing

end

"""
    function calc_reco_score(recommender::CollFilteringSVD, cust_idx::Vector{Int64})

Return sparse raw score matrix for recommended new products for customers.

recommnder:             CollFilteringSVD type object
cust_idx:               Indices of customers to generate reco for
"""

function calc_reco_score(recommender::CollFilteringSVD, cust_idx::Vector{Int64})

    # sparse matrix to store recommendations
    prod_cust_raw_score = spzeros(length(recommender.prod_idx_map), length(recommender.cust_idx_map))      # customer in column

    # empty sparse matrix with similar customers in rows, customers in columns
    similar_cust_cust_sim = spzeros(length(recommender.cust_idx_map), length(recommender.cust_idx_map))

    # populate with similarity for customers in agrument
    for this_cust_idx in cust_idx
        for (i, this_similar_cust_idx) in enumerate(@view recommender.similar_cust_idx[recommender.cust_idx .== this_cust_idx])
            similar_cust_cust_sim[this_similar_cust_idx, this_cust_idx] = recommender.similarity[recommender.cust_idx .== this_cust_idx][i]
        end
    end

    # caculate raw reco scores for products for each customer
    prod_cust_raw_score = recommender.prod_cust_rating * similar_cust_cust_sim

    # zero out score if customer has raing for product
    for (i, j, _) in zip(findnz(recommender.prod_cust_rating)...)
        prod_cust_raw_score[i, j] = 0
    end

    return prod_cust_raw_score
    
end

# predict
"""
    function ProductReco.predict(recommender::CollFilteringSVD, predict_cust::Vector{Customer})::Vector{CustomerProductReco} 

Return vector of customer product recommendations.

recommnder:     CollFilteringSVD type object
predict_cust:   Customers for whom recommendations to be predicted 
"""

function ProductReco.predict(recommender::CollFilteringSVD, predict_cust::Vector{Customer})::Vector{CustomerProductReco} 

    # check error in call to predict
    check_error_in_predict_call(recommender, predict_cust)

    # pre-allocate array to accumate predictions
    n_reco = min(length(recommender.prod_idx_map), recommender.n_max_reco_per_cust)    # recommendations per customer
    max_len = length(predict_cust) * recommender.n_max_reco_per_cust                   # max length of array

    prod_reco = (
        nrow = Vector{Int64}(undef, 1),                                                # counter of recos stored
        cust_idx=Vector{Int64}(undef, max_len), 
        prod_idx=Vector{Int64}(undef, max_len), 
        raw_score=Vector{Float64}(undef, max_len)
    )
    
    prod_reco[:nrow][1] = 0     # initialize record count

    # customer indices
    cust_id = id.(predict_cust)
    cust_idx = [recommender.cust_idx_map[id] for id in cust_id]

    # generate raw scores
    prod_cust_raw_score = calc_reco_score(recommender, cust_idx)

    # retain top scored products
    for (this_cust_idx, prod_score_col) in enumerate(eachcol(prod_cust_raw_score))

        # extract non-zero prod scores from sparse vector
        nz_prod_score_col = findnz(prod_score_col)
        prod_idx = nz_prod_score_col[1]
        raw_score = nz_prod_score_col[2]
        
        # remove prod with score floating point 0.0
        nz_slice = raw_score .!== 0.0               # on rhs integer 0 does not create right slice
        prod_idx = prod_idx[nz_slice]
        raw_score = raw_score[nz_slice]

        # if number of products more than n_reco then retain top n_reco
        if length(prod_idx) > n_reco

            top_slice = sortperm(raw_score, rev=true)[1:n_reco]
            prod_idx = prod_idx[top_slice]
            raw_score = raw_score[top_slice]
            
        end 

        # save in accumulator
        nrow_start = prod_reco[:nrow][1] + 1
        add_recs = length(prod_idx)
        nrow = prod_reco[:nrow][1] = nrow_start + add_recs - 1

        prod_reco[:cust_idx][nrow_start:nrow] = fill(this_cust_idx, add_recs)
        prod_reco[:prod_idx][nrow_start:nrow] = prod_idx
        prod_reco[:raw_score][nrow_start:nrow] = raw_score

    end  # end processing all cust

    # convert raw score to relative score
    nrow = prod_reco[:nrow][1]

    # percentile rank requires at least two records
    if nrow < 2
        relative_score = fill(100, nrow)
    else
        raw_score = @view prod_reco[:raw_score][1:nrow]
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in @view prod_reco[:cust_idx][1:nrow]]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in @view prod_reco[:prod_idx][1:nrow]]

    # return tuple
    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
