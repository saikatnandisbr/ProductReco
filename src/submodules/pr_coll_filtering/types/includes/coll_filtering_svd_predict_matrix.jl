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
    function prod_cust_raw_score(recommender::CollFilteringSVD, cust_idx::Vector::{Int64}, raw_score::SparseMatrixCSC, fn_score::Function=dot)

Return raw score for new products for customer.

recommnder:             CollFilteringSVD type object
cust_idx:               Indices of customers to generate reco for
raw_score:              Sparse matrix to populate with customer in column
fn_score:               Function to calculate recommendation score using vectors of similarity and rating
"""

function prod_cust_raw_score(recommender::CollFilteringSVD, cust_idx::Vector{Int64}, raw_score::AbstractMatrix, fn_score::Function=dot)

    println("inside matrix")

    # empty sparse matrix with similar customers in rows, customers in columns
    similar_cust_cust_sim = spzeros(length(recommender.cust_idx_map), length(recommender.cust_idx_map))

    # populate with similarity for customers in agrument
    for this_cust_idx in cust_idx
        for (i, this_similar_cust_idx) in enumerate(@view recommender.similar_cust_idx[recommender.cust_idx .== this_cust_idx])
            similar_cust_cust_sim[this_similar_cust_idx, this_cust_idx] = recommender.similarity[recommender.cust_idx .== this_cust_idx][i]
        end
    end

    # caculate raw reco scores for products for each customer
    for i in axes(recommender.prod_cust_rating, 1)     # ratings by in rows
        for j in cust_idx                              # customers in columns

            # compute score for prod if not rated by cust
            !iszero(recommender.prod_cust_rating[i, j]) && continue
            
            raw_score[i, j] = fn_score(recommender.prod_cust_rating[i, :], similar_cust_cust_sim[:, j])

        end
    end

    return nothing
    
end

# predict
"""
    function ProductReco.predict(recommender::CollFilteringSVD, predict_cust::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 

Return vector of customer product recommendations.

recommnder:     CollFilteringSVD type object
predict_cust:   Customers for whom recommendations to be predicted 
fn_score:       Function to calculate recommendation score using vectors of similarity and rating
"""

function ProductReco.predict(recommender::CollFilteringSVD, predict_cust::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 


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
    
    prod_reco[:nrow][1] = 0     # initialize

    # sparse matrix to store recommendations
    raw_score = spzeros(length(recommender.prod_idx_map), length(recommender.cust_idx_map))      # customer in column

    # customer indices
    cust_id = id.(predict_cust)
    cust_idx = [recommender.cust_idx_map[id] for id in cust_id]

    # generate raw scores
    prod_cust_raw_score(recommender, cust_idx, raw_score, fn_score)

    # retain top scored products
    for (j, col) in enumerate(eachcol(raw_score))                 # j is customer index
        for i in sortperm(col, rev=true)[1:n_reco]                # i is product index
            nrow = prod_reco[:nrow][1] += 1

            prod_reco[:cust_idx][nrow] = j
            prod_reco[:prod_idx][nrow] = i
            prod_reco[:raw_score][nrow] = raw_score[i, j]

        end
    end

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
