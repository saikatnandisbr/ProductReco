# find top similar customers

# imports
using SparseArrays
using Base.Threads

"""
    function top_similar_customers_threaded(fn::Function, top_n::Int64, cust_prod_rating::T) where {T <: Union{Matrix{Float64}, SparseMatrixCSC}}

Returns top_n similar customers for each customer and measure of similarity between the pairs.

fn:                     Function returing similarity between two vectors; higher similarity means more similar
top_n:                  Number of most similar customers to find
cust_prod_ratings:      Sparse ratings matrix with columns in rows and products in columns
"""

function top_similar_customers_threaded(fn::Function, top_n::Int64, cust_prod_rating::T) where {T <: Union{Matrix{Float64}, SparseMatrixCSC}}

    n_available_threads = nthreads()                          # number of Threads
    len_data = size(cust_prod_rating, 1)                      # length of data to be split among threads
    chunk_size = ceil(Int, len_data / n_available_threads)    # chunk size to be handled by each thread

    # indices of data to be handled by each thread
    thread_idx = [collect(i:min(i + chunk_size - 1, len_data)) for i in 1:chunk_size:len_data]

    # different from number of available threads for very small data size
    n_threads = length(thread_idx)

    # vectors to store output from each thread
    cust_idx = [Vector{Int64}() for i in 1:n_threads]
    similar_cust_idx = [Vector{Int64}() for i in 1:n_threads]
    similarity = [Vector{Float64}() for i in 1:n_threads]

    println("$n_threads $chunk_size")
    for i in 1:n_threads
        sizehint!(cust_idx[1], chunk_size)
        sizehint!(similar_cust_idx[1], chunk_size)
        sizehint!(similarity[1], chunk_size)
    end

    # threadify the outer loop
    # loop through all customer recrods
    # for each customer generate list of top simialr customers
    @sync begin

        # loop for each thread
        for thread_number in 1:n_threads

            # spawn thread
            Threads.@spawn begin

                # allocate once outside loop
                top_n_similar = fill(0, top_n)             # used to store indices of top similar customers
                top_n_similarity = fill(-Inf, top_n)       # used to store similarity of top similar customers

                # each thread handles its own slice of data
                for this_cust_idx in thread_idx[thread_number]
                    
                    # initialize for each loop
                    top_n_similar .= 0
                    top_n_similarity .= -Inf

                    for compared_cust_idx in 1:size(cust_prod_rating, 1)

                        # skip calculation of similarity with self
                        this_cust_idx == compared_cust_idx && continue

                        # similarity measure using function passed
                        sim_score = fn(cust_prod_rating[this_cust_idx, :], cust_prod_rating[compared_cust_idx, :])

                        # if this pair more similar than least similar pair in top n list then replace the least similar so far with new pair
                        if sim_score > minimum(top_n_similarity)
                            replace_idx = argmin(top_n_similarity)
                            top_n_similar[replace_idx] = compared_cust_idx
                            top_n_similarity[replace_idx] = sim_score
                        end
                    end

                    similar_custs_found = length(top_n_similar[top_n_similar .!= 0])

                    # write output to thread's own array
                    append!(cust_idx[thread_number], fill(this_cust_idx, similar_custs_found))
                    append!(similar_cust_idx[thread_number], top_n_similar[top_n_similar .!= 0])
                    
                    top_n_similarity = round.(top_n_similarity, digits=4)
                    append!(similarity[thread_number], top_n_similarity[top_n_similar .!= 0])

                end
            
            end

        end

    end

    # concatenate outputs from separate threads before returning
    return vcat(cust_idx...), vcat(similar_cust_idx...), vcat(similarity...)

end