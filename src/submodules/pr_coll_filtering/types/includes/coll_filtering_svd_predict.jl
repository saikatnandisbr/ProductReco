# helper functions used by predict
"""
    function check_error_in_predict_call(recommender::CollFilteringSVD, customer::Vector{Customer})

Raise error if exception conditions exist in agruments to predict.

recommnder:     CollFilteringSVD type object
customer:       Customers for whom recommendations to be predicted 
"""

function check_error_in_predict_call(recommender::CollFilteringSVD, customer::Vector{Customer})

    !ProductReco.istransformed(recommender) && error("ProductReco.predict: Recommender not transformed, cannot continue")

    # check if each customer exists in transformed recommender
    try

        predict_cust_id = id.(customer)
        _ = [recommender.cust_idx_map[id] for id in predict_cust_id]       

    catch err

        println("ProductReco.predict: Customer not present in transformed data, cannot continue")
        error(err)
        
    end

    return nothing

end

"""
    function prod_from_similar_cust(recommender::CollFilteringSVD, predict_cust_idx::Int64)

Return list of products rated by similar customers, along with customer similarity and product rating values.

recommnder:             CollFilteringSVD type object
predict_cust_idx:       Customer index 
similar_cust_rating:    Named tuple to populate
"""

function prod_from_similar_cust(recommender::CollFilteringSVD, predict_cust_idx::Int64, similar_cust_rating::NamedTuple)

    # products of predict customer - to be excluded from candidate output
    predict_cust_prod_idx = findnz(recommender.prod_cust_rating[:, predict_cust_idx])[1]

    # similar customers and similarity
    similar_cust_slice = recommender.cust_idx .== predict_cust_idx
    similar_cust_idx = @view recommender.similar_cust_idx[similar_cust_slice]
    similarity =       @view recommender.similarity[similar_cust_slice]

    # loop through similar customers
    for (i, curr_similar_cust_idx) in enumerate(similar_cust_idx)
        
        similar_cust_prod_idx = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[1]
        similar_cust_prod_rating = findnz(recommender.prod_cust_rating[:, curr_similar_cust_idx])[2]

        # loop throught products of similar customers
        for (j, curr_similar_cust_prod_idx) in enumerate(similar_cust_prod_idx)

            # skip if predict customer rated similar customer product
            in(curr_similar_cust_prod_idx, predict_cust_prod_idx) && continue

            # record counter
            nrow = similar_cust_rating[:nrow][1] = similar_cust_rating[:nrow][1] + 1       

            # data
            similar_cust_rating[:cust_idx][nrow] = curr_similar_cust_idx
            similar_cust_rating[:similarity][nrow] = similarity[i]
            similar_cust_rating[:prod_idx][nrow] = curr_similar_cust_prod_idx
            similar_cust_rating[:rating][nrow] = similar_cust_prod_rating[j]

        end  # end loop for products of similar customers
        
    end  # end loop for similar customers 

    return nothing
end

"""
    function top_reco_for_customer(fn_score::Function, similar_cust_rating::NamedTuple, cust_prod_reco::NamedTuple)

Return top recommendations for given customer.

recommnder:             CollFilteringSVD type object
fn_score:               Function to calculate recommendation score using vectors of similarity and rating
similar_cust_rating:    Input products rated by similar customers
cust_prod_reco:         Output top recos for customer
"""

function top_reco_for_customer(recommender::CollFilteringSVD, fn_score::Function, similar_cust_rating::NamedTuple, cust_prod_reco::NamedTuple)

    # score candidate products
    nrow = similar_cust_rating[:nrow][1]

    for curr_prod_idx in unique(similar_cust_rating[:prod_idx][1:nrow])
    
        # slice similar customer similarity rating records by product
        prod_slice = similar_cust_rating[:prod_idx][1:nrow] .== curr_prod_idx         

        # get customer similarity and customer rating for the product
        similarity = @views similar_cust_rating[:similarity][1:nrow][prod_slice]
        rating =     @views similar_cust_rating[:rating][1:nrow][prod_slice]

        score = round(fn_score(similarity, rating), digits=4)
    
        # add to accumulator
        nrow_out = cust_prod_reco[:nrow][1] = cust_prod_reco[:nrow][1] + 1

        cust_prod_reco[:prod_idx][nrow_out] = curr_prod_idx
        cust_prod_reco[:raw_score][nrow_out] = score
    end

    # top score products
    nrow = cust_prod_reco[:nrow][1]
    n_reco = min(recommender.n_max_reco_per_cust, nrow)                             # number of recommendations for customer
        
    sort_seq = sortperm(cust_prod_reco[:raw_score][1:nrow], rev=true)               # sort by score descending
    
    top_prod_idx =   @views cust_prod_reco[:prod_idx][1:nrow][sort_seq][1:n_reco]   # top products
    top_prod_score = @views cust_prod_reco[:raw_score][1:nrow][sort_seq][1:n_reco]  # top scores

    # update output with top score products
    cust_prod_reco[:nrow][1] = n_reco
    cust_prod_reco[:prod_idx][1:n_reco] = top_prod_idx
    cust_prod_reco[:raw_score][1:n_reco] = top_prod_score

    return nothing

end

# predict
"""
    function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 

Return vector of customer product recommendations.

recommnder:     CollFilteringSVD type object
customer:       Customers for whom recommendations to be predicted 
fn_score:       Function to calculate recommendation score using vectors of similarity and rating
"""

function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 


    # check error in call to predict
    check_error_in_predict_call(recommender, customer)

    # accumulate predictions
    max_len = length(customer) * recommender.n_max_reco_per_cust
    prod_reco = (
        nrow = Vector{Int64}(undef, 1), 
        cust_idx=Vector{Int64}(undef, max_len), 
        prod_idx=Vector{Int64}(undef, max_len), 
        raw_score=Vector{Float64}(undef, max_len)
    )

    # accumulate product recommendations for given customer
    # initially store all candidates, later choose top ones
    max_len = length(recommender.prod_idx_map)
    cust_prod_reco = (
        nrow = Vector{Int64}(undef, 1), 
        prod_idx=Vector{Int64}(undef, max_len), 
        raw_score=Vector{Float64}(undef, max_len)
    )

    # accumulate products rated by customers similar to given customer
    max_len = length(recommender.prod_idx_map) * recommender.n_max_similar_cust
    similar_cust_rating = (
        nrow = Vector{Int64}(undef, 1), 
        cust_idx = Vector{Int64}(undef, max_len), 
        similarity = Vector{Float64}(undef, max_len), 
        prod_idx = Vector{Int64}(undef, max_len),
        rating = Vector{Float64}(undef, max_len)
    )

    # customer indices from ids
    predict_cust_id = id.(customer)   
    predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]

    # generate reco for each customer
    prod_reco[:nrow][1] = 0                     # initialize once

    for (i, curr_predict_cust_idx) in enumerate(predict_cust_idx)

        # products rated by similar customers
        similar_cust_rating[:nrow][1] = 0       # initialize counter for each customer
        prod_from_similar_cust(recommender, curr_predict_cust_idx, similar_cust_rating)

        # score and pick top candidates for each customer
        cust_prod_reco[:nrow][1] = 0            # initialize counter for each customer
        top_reco_for_customer(recommender, fn_score, similar_cust_rating, cust_prod_reco)

        # add to overall accumulator
        row_start = prod_reco[:nrow][1] + 1
        rec_count = cust_prod_reco[:nrow][1]
        row_end = row_start + rec_count - 1

        prod_reco[:nrow][1] = row_end           # new record count

        prod_reco[:cust_idx][row_start:row_end] = fill(curr_predict_cust_idx, rec_count)
        prod_reco[:prod_idx][row_start:row_end] = @view cust_prod_reco[:prod_idx][1:rec_count]
        prod_reco[:raw_score][row_start:row_end] = @view cust_prod_reco[:raw_score][1:rec_count]

    end

    # convert raw score to relative score
    n_reco = prod_reco[:nrow][1]

    # percentile rank requires at least two records
    if n_reco < 2
        relative_score = fill(100, n_reco)
    else
        raw_score = @view prod_reco[:raw_score][1:n_reco]
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in prod_reco[:cust_idx][1:n_reco]]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in prod_reco[:prod_idx][1:n_reco]]

    # return tuple
    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
