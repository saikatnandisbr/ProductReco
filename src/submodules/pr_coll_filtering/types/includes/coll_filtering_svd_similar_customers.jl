"""
    function similar_customers(cf::CollFilteringSVD, agrs...; kwargs...)::Vector{Customer}

Returns vector of customers similar to a given customer

cf:         CollFilteringSVD type object
agrs:       Tuple of variable number of arguments
kwargs:     Tuple of variable number of keyword arguments 
"""

function PRCollFiltering.similar_customers(cf::CollFilteringSVD, cust::Customer)::Vector{SimilarCustomer}

    !ProductReco.istransformed(cf) && error("Recommender not transformed, cannot return similar customers")

    cust_id = id(cust)                              # customer id
    cust_idx = cf.cust_idx_map[cust_id]             # customer index in sparse array

    # similar customer index
    similar_cust_idx = cf.similar_cust_idx[cf.cust_idx .== cust_idx]
    similarity = cf.similarity[cf.cust_idx .== cust_idx]      

    # reverse lookup customer id from customer index
    similar_cust_id = [key for (key, val) in cf.cust_idx_map if val ∈ similar_cust_idx]

    # map customer constructor over ids
    customer = map(Customer, similar_cust_id)

    similar_customer = [(customer[i], similarity[i]) for i in 1:length(customer)]

    return similar_customer
end
