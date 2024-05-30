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

Identify top recommendations for customers, populate prod_reco with these recommendations.

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
        for (i, this_similar_cust_idx) in enumerate(recommender.similar_cust_idx[recommender.cust_idx .== this_cust_idx])
            similar_cust_cust_sim[this_similar_cust_idx, this_cust_idx] = recommender.similarity[recommender.cust_idx .== this_cust_idx][i]
        end
    end

    # number of max reco per customer
    n_reco_per_cust = min(length(recommender.prod_idx_map), recommender.n_max_reco_per_cust) 

    # pre-allocate vectors to store prod recs for each customer
    prod_idx_vec = collect(1:length(recommender.prod_idx_map))
    prod_score_vec = Vector{Float64}(undef, length(recommender.prod_idx_map))

    for (this_cust_idx, similarity_vec) in enumerate(eachcol(similar_cust_cust_sim))
        
        # scores for candidate products
        prod_score_vec = [fn_score(rating_vec, similarity_vec) for rating_vec in eachrow(recommender.prod_cust_rating)]

        # omit product if already rated by customer
        for this_prod_idx in findnz(recommender.prod_cust_rating[:, this_cust_idx])[1]
            prod_score_vec[this_prod_idx] = 0.0
        end

        # remove prod with score floating point 0.0
        prod_idx_nz_vec = @view prod_idx_vec[prod_score_vec .!= 0.0]
        prod_score_nz_vec = @view prod_score_vec[prod_score_vec .!== 0.0]

        # if no product for customer then skip to next customer
        (length(prod_idx_nz_vec) == 0) && continue

        # retain top products for customer
        if length(prod_idx_nz_vec) > n_reco_per_cust

            top_slice = sortperm(prod_score_nz_vec, rev=true)[1:n_reco_per_cust]
            prod_idx_top_vec = @view prod_idx_nz_vec[top_slice]
            prod_score_top_vec = @view prod_score_nz_vec[top_slice]

        else

            prod_idx_top_vec = @view prod_idx_nz_vec[:]
            prod_score_top_vec = @view prod_score_nz_vec[:]

        end 

        # save in accumulator
        add_rows = length(prod_idx_top_vec)
        nrow_start = prod_reco[:nrow][1] + 1
        nrow_end = prod_reco[:nrow][1] = nrow_start + add_rows - 1

        prod_reco[:cust_idx][nrow_start:nrow_end] = fill(this_cust_idx, add_rows)
        prod_reco[:prod_idx][nrow_start:nrow_end] = prod_idx_top_vec
        prod_reco[:raw_score][nrow_start:nrow_end] = prod_score_top_vec

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

    # set up for multi-threading
    n_available_threads = nthreads()                          # number of Threads
    len_data = length(predict_cust)                           # number of customers
    chunk_size = ceil(Int, len_data / n_available_threads)    # chunk size to be handled by each thread

    # indices of data to be handled by each thread
    thread_idx = [collect(i:min(i + chunk_size - 1, len_data)) for i in 1:chunk_size:len_data]

    # different from number of available threads for very small data size
    n_threads = length(thread_idx)

    # pre-allocate collection to accumate recommendations from each thread
    n_reco_per_cust = min(length(recommender.prod_idx_map), recommender.n_max_reco_per_cust)        # recommendations per customer
    max_len = length(predict_cust) * n_reco_per_cust                                                # max length for output vectors
    max_len_per_thread = ceil(Int, max_len / n_threads)                                             # max length per thread

    # define array of named tuples, one tuple for each thread
    prod_reco = [
            (
            nrow = Vector{Int64}(undef, 1),
            cust_idx=Vector{Int64}(undef, max_len_per_thread), 
            prod_idx=Vector{Int64}(undef, max_len_per_thread), 
            raw_score=Vector{Float64}(undef, max_len_per_thread)
            )
        for i in 1:n_threads]

    # initialize record count for each thread
    for i in 1:n_threads
        prod_reco[i][:nrow][1] = 0
    end

    # combined output from all threads
    prod_reco_combined = (
        nrow = Vector{Int64}(undef, 1),
        cust_idx=Vector{Int64}(undef, max_len), 
        prod_idx=Vector{Int64}(undef, max_len), 
        raw_score=Vector{Float64}(undef, max_len)
    )

    # customer indices
    cust_id = id.(predict_cust)
    cust_idx = [recommender.cust_idx_map[id] for id in cust_id]

    # generate top product recommendations for customers
    @sync begin
        
        for thread_num in 1:n_threads

            Threads.@spawn begin

                # separate slice of pro_reco for each thread to populate
                top_prod_for_cust(recommender, cust_idx[thread_idx[thread_num]], prod_reco[thread_num], fn_score)

            end  # end @spawn

        end  # end loop for threads

    end  # end @sync

    # combine outputs from threads
    nrow = prod_reco_combined[:nrow][1] = sum([prod_reco[i][:nrow][1] for i in 1:n_threads])

    prod_reco_combined[:cust_idx][1:nrow] = vcat([prod_reco[i][:cust_idx][1:prod_reco[i][:nrow][1]] for i in 1:n_threads]...)
    prod_reco_combined[:prod_idx][1:nrow] = vcat([prod_reco[i][:prod_idx][1:prod_reco[i][:nrow][1]] for i in 1:n_threads]...)
    prod_reco_combined[:raw_score][1:nrow] = vcat([prod_reco[i][:raw_score][1:prod_reco[i][:nrow][1]] for i in 1:n_threads]...)

    # convert raw score to relative score
    if nrow < 2                                 # percentile rank requires at least two records
        relative_score = fill(100, nrow)
    else
        raw_score = prod_reco_combined[:raw_score][1:nrow]
        relative_score = [ceil(Int, percentilerank(raw_score, s)) for s in raw_score]
    end

    # convert idx to id
    idx_cust_map = Dict(values(recommender.cust_idx_map) .=> keys(recommender.cust_idx_map))
    reco_cust_id = [idx_cust_map[key] for key in prod_reco_combined[:cust_idx][1:nrow]]
    
    idx_prod_map = Dict(values(recommender.prod_idx_map) .=> keys(recommender.prod_idx_map))
    reco_prod_id = [idx_prod_map[key] for key in prod_reco_combined[:prod_idx][1:nrow]]

    # return tuple
    return collect(zip(reco_cust_id, reco_prod_id, relative_score))
end
