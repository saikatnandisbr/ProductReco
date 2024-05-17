# find top similar customers

# imports
using SparseArrays      # in standard library

"""
    function top_similar_customers(fn::Function, top_n::Int64, cust_prod_ratings::SparseMatrixCSC)::(Matrix{Int64}, Vector{Float64})

Returns top_n similar customers for each customer and measure of similarity between the pairs.

fn:                     Function returing similarity between two vectors; higher similarity means more similar
top_n:                  Number of most similar customers to find
cust_prod_ratings:      Sparse ratings matrix with columns in rows and products in columns
"""

function top_similar_customers(fn::Function, top_n::Int64, cust_prod_rating::SparseMatrixCSC)

    # vectors to store final output
    cust = Vector{Int64}()
    similar_cust = Vector{Int64}()
    similarity = Vector{Float64}()

    # loop through all customer recrods
    # for each customer generate list of top simialr customers
    for cust_idx in 1:size(cust_prod_rating, 1)

        # vectors used in loop over all customers
        top_n_similar = fill(0, top_n)             # used to store indices of top similar customers
        top_n_similarity = fill(-Inf, top_n)       # used to store similarity of top similar customers

        for compared_cust_idx in 1:size(cust_prod_rating, 1)

            # skip calculation of similarity with self
            cust_idx == compared_cust_idx && continue

            # similarity measure using function passed
            # materialize necessary customer vector pair from sparse array
            sim_score = fn(Vector(cust_prod_rating[cust_idx, :]), Vector(cust_prod_rating[compared_cust_idx, :]))

            # if this pair more similar than least similar pair in top n list then replace the least similar so far with new pair
            if sim_score > minimum(top_n_similarity)
                replace_idx = argmin(top_n_similarity)
                top_n_similar[replace_idx] = compared_cust_idx
                top_n_similarity[replace_idx] = sim_score
            end
        end

        similar_custs_found = length(top_n_similar[top_n_similar .!= 0])

        append!(cust, fill(cust_idx, similar_custs_found))
        append!(similar_cust, top_n_similar[top_n_similar .!= 0])
        
        top_n_similarity = round.(top_n_similarity, digits=4)
        append!(similarity, top_n_similarity[top_n_similar .!= 0])

    end

    # matrix of customer similar customer indices
    similar_cust_pair = hcat(cust, similar_cust)

    return similar_cust_pair, similarity
end
