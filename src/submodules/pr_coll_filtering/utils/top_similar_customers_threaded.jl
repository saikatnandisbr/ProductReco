# find top similar customers

# imports
using SparseArrays
using Base.Threads

"""
    function top_similar_customers_threaded(fn::Function, top_n::Int64, cust_prod_rating::T) where {T <: Union{Matrix{Float64}, SparseMatrixCSC}}

Returns top_n similar customers for each customer and measure of similarity between the pairs.

fn:                     Function returing similarity between two vectors; higher similarity means more similar
top_n:                  Number of most similar customers to find
cust_prod_rating:       Sparse ratings matrix with columns in rows and products in columns
"""

function top_similar_customers_threaded(fn::Function, top_n::Int64, prod_cust_rating::T) where {T <: Union{Matrix{Float64}, SparseMatrixCSC}}

    n_available_threads = nthreads()                          # number of Threads
    len_data = size(prod_cust_rating, 2)                      # length of data to be split among threads
    chunk_size = ceil(Int, len_data / n_available_threads)    # chunk size to be handled by each thread

    # indices of data to be handled by each thread
    thread_idx = [collect(i:min(i + chunk_size - 1, len_data)) for i in 1:chunk_size:len_data]

    # different from number of available threads for very small data size
    n_threads = length(thread_idx)

    # vectors to store output from each thread
    cust_idx = [Vector{Int64}(undef, chunk_size * top_n) for i in 1:n_threads]
    similar_cust_idx = [Vector{Int64}(undef, chunk_size * top_n) for i in 1:n_threads]
    similarity = [Vector{Float64}(undef, chunk_size * top_n) for i in 1:n_threads]

    # threadify the outer loop
    # loop through all customer recrods
    # for each customer generate list of top simialr customers
    @sync begin

        # loop for each thread
        for thread_number in 1:n_threads

            # spawn thread
            Threads.@spawn begin

                # starting location in thread specific array to update
                curr_loc = 1

                # allocate once outside loop
                top = Vector{Int64}(undef, top_n)                    # used to store index of given customer
                top_similar = Vector{Int64}(undef, top_n)            # used to store indices of top similar customers
                top_similarity = Vector{Float64}(undef, top_n)       # used to store similarity of top similar customers

                # each thread handles its own slice of data
                for this_cust_idx in thread_idx[thread_number]
                    
                    # initialize for each loop
                    top .= this_cust_idx
                    top_similar .= 0
                    top_similarity .= -Inf

                    for compared_cust_idx in 1:size(prod_cust_rating, 2)

                        # skip calculation of similarity with self
                        this_cust_idx == compared_cust_idx && continue

                        # similarity measure using function passed
                        sim_score = fn(view(prod_cust_rating, :, this_cust_idx), view(prod_cust_rating, :, compared_cust_idx))

                        # if this pair more similar than least similar pair in top n list then replace the least similar so far with new pair
                        if sim_score > minimum(top_similarity)
                            replace_idx = argmin(top_similarity)
                            top_similar[replace_idx] = compared_cust_idx
                            top_similarity[replace_idx] = sim_score
                        end
                    end

                    count_similar = length(top_similar[top_similar .!= 0])

                    # write loop output to thread array
                    setindex!(cust_idx[thread_number],         top[top_similar .!= 0],             curr_loc:curr_loc+count_similar-1)
                    setindex!(similar_cust_idx[thread_number], top_similar[top_similar .!= 0],     curr_loc:curr_loc+count_similar-1)
                    setindex!(similarity[thread_number],       top_similarity[top_similar .!= 0],  curr_loc:curr_loc+count_similar-1)

                    # update location in array
                    curr_loc += count_similar

                end

                # update final size of arrays for thread
                resize!(cust_idx[thread_number], curr_loc-1)
                resize!(similar_cust_idx[thread_number], curr_loc-1)
                resize!(similarity[thread_number], curr_loc-1)
            
            end

        end

    end

    # concatenate outputs from separate threads before returning
    return vcat(cust_idx...), vcat(similar_cust_idx...), vcat(similarity...)

end