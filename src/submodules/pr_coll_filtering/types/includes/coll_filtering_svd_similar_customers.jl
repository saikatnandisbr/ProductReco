"""
    function similar_customers(cf::CollFilteringSVD, agrs...; kwargs...)::Vector{Customer}

Returns vector of customers similar to a given customer

cf:         CollFilteringSVD type object
agrs:       Tuple of variable number of arguments
kwargs:     Tuple of variable number of keyword arguments 
"""

function PRCollFiltering.similar_customers(cf::CollFilteringSVD, cust::Customer)::Vector{SimilarCustomer}

    !ProductReco.istransformed(cf) && error("PRCollFiltering.similar_customers: Recommender not transformed, cannot continue")

    # customer id
    cust_id = id(cust)

    # customer index
    try
        cust_idx = cf.cust_idx_map[cust_id]        
    catch err
        println("PRCollFiltering.similar_customers: Customer not present in transformed data, cannot continue")
        error(err)
    end
                
    # if no error above, can proceed
    cust_idx = cf.cust_idx_map[cust_id]       # calculate again as try block above has own scope    

    # similar customer index
    similar_cust_idx = cf.similar_cust_idx[cf.cust_idx .== cust_idx]
    similarity = cf.similarity[cf.cust_idx .== cust_idx]      

    # reverse lookup customer id from customer index
    idx_cust_map = Dict(values(cf.cust_idx_map) .=> keys(cf.cust_idx_map))
    similar_cust_id = [idx_cust_map[key] for key in similar_cust_idx]

    # map customer constructor over ids
    customer = map(Customer, similar_cust_id)

    similar_customer = [(customer[i], similarity[i]) for i in 1:length(customer)]

    return similar_customer
end
