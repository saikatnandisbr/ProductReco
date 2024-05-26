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
    function top_prod_for_cust(recommender::CollFilteringSVD, cust_idx::Vector{Int64}, fn_score::Function, prod_reco::NamedTuple)

Return sparse raw score matrix for recommended new products for customers.

recommnder:             CollFilteringSVD type object
cust_idx:               Indices of customers to generate reco for
prod_reco:              Pre-allocated tuple to accumulate recommendations
fn_score:               Function to calculate score from similairty and rating
"""

function top_prod_for_cust(recommender::CollFilteringSVD, cust_idx::Vector{Int64}, prod_reco::NamedTuple, fn_score::Function=dot)

    # empty sparse matrix with similar customers in rows, customers in columns
    similar_cust_cust_sim = spzeros(length(recommender.cust_idx_map), length(recommender.cust_idx_map))

    # populate with similarity for customers in agrument
    for this_cust_idx in cust_idx
        for (i, this_similar_cust_idx) in enumerate(@view recommender.similar_cust_idx[recommender.cust_idx .== this_cust_idx])
            similar_cust_cust_sim[this_similar_cust_idx, this_cust_idx] = recommender.similarity[recommender.cust_idx .== this_cust_idx][i]
        end
    end

    # number of max reco per customer
    n_reco = min(length(recommender.prod_idx_map), recommender.n_max_reco_per_cust) 

    for (this_cust_idx, similarity_vec) in enumerate(eachcol(similar_cust_cust_sim))
        
        # scores for candidate products
        prod_score_vec = [fn_score(rating_vec, similarity_vec) for rating_vec in eachrow(recommender.prod_cust_rating)]

        # omit product if already rated by customer
        for this_prod_idx in findnz(recommender.prod_cust_rating[:, this_cust_idx])[1]
            prod_score_vec[this_prod_idx] = 0.0
        end

        # remove prod with score floating point 0.0
        prod_idx_vec = [idx for idx in eachindex(prod_score_vec) if prod_score_vec[idx] .!== 0.0]
        prod_score_vec = prod_score_vec[prod_score_vec .!== 0.0]

        # if no product for customer then skip to next customer
        (length(prod_idx_vec) == 0) && continue

        # retain top products for customer
        if length(prod_idx_vec) > n_reco

            top_slice = sortperm(prod_score_vec, rev=true)[1:n_reco]
            prod_idx_vec = prod_idx_vec[top_slice]
            prod_score_vec = prod_score_vec[top_slice]
            
        end 

        # save in accumulator
        add_rows = length(prod_idx_vec)
        nrow_start = prod_reco[:nrow][1] + 1
        nrow_end = prod_reco[:nrow][1] = nrow_start + add_rows - 1

        prod_reco[:cust_idx][nrow_start:nrow_end] = fill(this_cust_idx, add_rows)
        prod_reco[:prod_idx][nrow_start:nrow_end] = prod_idx_vec
        prod_reco[:raw_score][nrow_start:nrow_end] = prod_score_vec

    end

    return nothing
    
end

# predict
"""
    function ProductReco.predict(recommender::CollFilteringSVD, predict_cust::Vector{Customer})::Vector{CustomerProductReco} 

Return vector of customer product recommendations.

recommnder:     CollFilteringSVD type object
predict_cust:   Customers for whom recommendations to be predicted 
fn_score:               Function to calculate score from similairty and rating
"""

function ProductReco.predict(recommender::CollFilteringSVD, predict_cust::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 

    # check error in call to predict
    check_error_in_predict_call(recommender, predict_cust)

    # pre-allocate collection to accumate recommendations
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

    # generate top product recommendations for customers
    top_prod_for_cust(recommender, cust_idx, prod_reco, fn_score)

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
