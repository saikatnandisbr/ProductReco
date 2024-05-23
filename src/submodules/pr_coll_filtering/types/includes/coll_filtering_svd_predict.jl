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

end

"""
    function prod_from_similar_cust(recommender::CollFilteringSVD, cust_idx::Int64)

Return list of products rated by similar customers, along with customer similarity and product rating values.

recommnder:     CollFilteringSVD type object
cust_idx:       Customer index 
"""

function prod_from_similar_cust(recommender::CollFilteringSVD, predict_cust_idx::Int64)

    # accumulator for candidate products
    # (similar_cust_idx, similarity, prod_idx, prod_rating)
    candidate_prod = Tuple((Vector{Int64}(), Vector{Float64}(), Vector{Int64}(), Vector{Float64}()))

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

            # accumulate new products
            push!(getfield(candidate_prod, 1), curr_similar_cust_idx)
            push!(getfield(candidate_prod, 2), similarity[i])
            push!(getfield(candidate_prod, 3), curr_similar_cust_prod_idx)
            push!(getfield(candidate_prod, 4), similar_cust_prod_rating[j])

        end  # end loop for products of similar customers
        
    end  # end loop for similar customers 

    return candidate_prod
end

"""
    function prod_reco_for_customer(recommender::CollFilteringSVD, predict_cust_idx::Int64, fn_score::Function)

Return top recommendations for given customer.

recommnder:     CollFilteringSVD type object
cust_idx:       Customer index
fn_score:       Function to calculate recommendation score using vectors of similarity and rating 
"""

function prod_reco_for_customer(recommender::CollFilteringSVD, predict_cust_idx::Int64, fn_score::Function)

    # accumulate product recommendations for given customer
    # (prod_idx, raw score)
    cust_prod_reco = Tuple((Vector{Int64}(), Vector{Float64}()))

    # products rated by similar customers
    candidate_prod = prod_from_similar_cust(recommender, predict_cust_idx)

    # score candidate products
    for curr_candidate_prod_idx in unique(getfield(candidate_prod, 3))
    
        # slice similar customer similarity rating records by product
        prod_slice = getfield(candidate_prod, 3) .== curr_candidate_prod_idx         

        # get customer similarity and customer rating for the product
        similarity = @view getfield(candidate_prod, 2)[prod_slice]
        rating =     @view getfield(candidate_prod, 4)[prod_slice]

        score = round(fn_score(similarity, rating), digits=4)
    
        # add to accumulator
        append!(getfield(cust_prod_reco, 1), curr_candidate_prod_idx)
        append!(getfield(cust_prod_reco, 2), score)    
    end

    # retain top score products
    n_reco = min(recommender.n_max_reco_per_cust, length(getfield(cust_prod_reco, 1)))   # number of recommendations for predict customer
        
    sort_seq = sortperm(getfield(cust_prod_reco, 2), rev=true)                           # sort by score descending
    
    top_prod_idx =   @view (@view getfield(cust_prod_reco, 1)[sort_seq])[1:n_reco]       # top products
    top_prod_score = @view (@view getfield(cust_prod_reco, 2)[sort_seq])[1:n_reco]       # top scores

    return (top_prod_idx, top_prod_score)

end

# predict
"""
    function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
customer:       Customers for whom recommendations to be predicted 
fn_score:       Function to calculate recommendation score using vectors of similarity and rating
"""

function ProductReco.predict(recommender::CollFilteringSVD, customer::Vector{Customer}, fn_score::Function=dot)::Vector{CustomerProductReco} 


    # check error in call to predict
    check_error_in_predict_call(recommender, customer)

    # allocate array to used to accumulate product recommendations
    # (cust_idx, prod_idx, raw score)
    prod_reco = Tuple((Vector{Int64}(), Vector{Int64}(), Vector{Float64}()))

    # customer indices from ids
    predict_cust_id = id.(customer)   
    predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]

    # generate reco for each customer
    for (i, curr_predict_cust_idx) in enumerate(predict_cust_idx)

        # generate reco
        cust_prod_reco = prod_reco_for_customer(recommender, curr_predict_cust_idx, fn_score)

        # add to accumulator
        n_reco_for_customer = length(getfield(cust_prod_reco, 1))

        append!(getfield(prod_reco, 1), fill(curr_predict_cust_idx, n_reco_for_customer))
        append!(getfield(prod_reco, 2), getfield(cust_prod_reco, 1))
        append!(getfield(prod_reco, 3), getfield(cust_prod_reco, 2))

    end

    # convert raw score to relative score
    n_reco = length(getfield(prod_reco, 1))
    if n_reco <= 2
        relative_reco_score = fill(100, n_reco)
    else
        raw_score = getfield(prod_reco, 3)                                              # raw scores across all generated recommendations
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]   # relative scores across all generated recommendations
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in getfield(prod_reco, 1)]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in getfield(prod_reco, 2)]

    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
