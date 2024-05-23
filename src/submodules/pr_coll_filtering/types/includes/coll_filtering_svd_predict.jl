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
"""

function prod_from_similar_cust(recommender::CollFilteringSVD, predict_cust_idx::Int64)

    # accumulator for candidate products
    # (similar_cust_idx, similarity, prod_idx, prod_rating)
    candidate_similar_cust_idx = Vector{Int64}()
    candidate_similarity = Vector{Float64}()
    candidate_prod_idx = Vector{Int64}()
    candidate_prod_rating = Vector{Float64}()

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
            push!(candidate_similar_cust_idx, curr_similar_cust_idx)
            push!(candidate_similarity, similarity[i])
            push!(candidate_prod_idx, curr_similar_cust_prod_idx)
            push!(candidate_prod_rating, similar_cust_prod_rating[j])

        end  # end loop for products of similar customers
        
    end  # end loop for similar customers 

    return candidate_similar_cust_idx, candidate_similarity, candidate_prod_idx, candidate_prod_rating
end

"""
    function prod_reco_for_customer(recommender::CollFilteringSVD, predict_cust_idx::Int64, fn_score::Function)

Return top recommendations for given customer.

recommnder:             CollFilteringSVD type object
predict_cust_idx:       Customer index
fn_score:               Function to calculate recommendation score using vectors of similarity and rating 
"""

function prod_reco_for_customer(recommender::CollFilteringSVD, predict_cust_idx::Int64, fn_score::Function)

    # accumulate product recommendations for given customer
    # (prod_idx, raw score)
    cust_prod_reco_prod_idx = Vector{Int64}()
    cust_prod_reco_raw_score = Vector{Float64}()

    # candidates for recommendation - products rated by similar customers
    candidate_similar_cust_idx, candidate_similarity, candidate_prod_idx, candidate_prod_rating = prod_from_similar_cust(recommender, predict_cust_idx)

    # score candidate products
    for curr_candidate_prod_idx in unique(candidate_prod_idx)
    
        # slice similar customer similarity rating records by product
        prod_slice = candidate_prod_idx .== curr_candidate_prod_idx         

        # get customer similarity and customer rating for the product
        similarity = @view candidate_similarity[prod_slice]
        rating =     @view candidate_prod_rating[prod_slice]

        score = round(fn_score(similarity, rating), digits=4)
    
        # add to accumulator
        append!(cust_prod_reco_prod_idx, curr_candidate_prod_idx)
        append!(cust_prod_reco_raw_score, score)    
    end

    # retain top score products
    n_reco = min(recommender.n_max_reco_per_cust, length(cust_prod_reco_prod_idx))       # number of recommendations for predict customer
        
    sort_seq = sortperm(cust_prod_reco_raw_score, rev=true)                              # sort by score descending
    
    top_prod_idx =   @view (@view cust_prod_reco_prod_idx[sort_seq])[1:n_reco]           # top products
    top_prod_score = @view (@view cust_prod_reco_raw_score[sort_seq])[1:n_reco]          # top scores

    return top_prod_idx, top_prod_score

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

    # accumulate product recommendations
    # (cust_idx, prod_idx, raw score)
    prod_reco_cust_idx = Vector{Int64}()
    prod_reco_prod_idx = Vector{Int64}()
    prod_reco_raw_score = Vector{Float64}()

    # customer indices from ids
    predict_cust_id = id.(customer)   
    predict_cust_idx = [recommender.cust_idx_map[id] for id in predict_cust_id]

    # generate reco for each customer
    for (i, curr_predict_cust_idx) in enumerate(predict_cust_idx)

        # generate reco
        top_prod_idx, top_prod_score = prod_reco_for_customer(recommender, curr_predict_cust_idx, fn_score)

        # add to accumulator
        n_reco_for_customer = length(top_prod_idx)

        append!(prod_reco_cust_idx, fill(curr_predict_cust_idx, n_reco_for_customer))
        append!(prod_reco_prod_idx, top_prod_idx)
        append!(prod_reco_raw_score, top_prod_score)

    end

    # convert raw score to relative score
    n_reco = length(prod_reco_cust_idx)
    if n_reco <= 2
        relative_score = fill(100, n_reco)
    else
        relative_score = [ceil(Int, percentilerank(prod_reco_raw_score, s)) for s in prod_reco_raw_score]
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in prod_reco_cust_idx]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in prod_reco_prod_idx]

    # return tuple
    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
