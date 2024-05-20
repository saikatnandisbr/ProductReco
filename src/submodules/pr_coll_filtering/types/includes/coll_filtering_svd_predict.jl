"""
    function predict(recommender::CollFilteringSVD, customers::Vector{Customer})::Vector{CustomerProductReco} 

Returns vector of customer product recommendations (::CustomerProductRecommendation).

recommnder:     CollFilteringSVD type object
agrs:           Tuple of variable number of arguments
kwargs:         Tuple of variable number of keyword arguments 
"""

function ProductReco.predict(recommender::CollFilteringSVD, customers::Vector{Customer})::Vector{CustomerProductReco}

    cust_id = id.(customers)
    cust_idx = [recommender.cust_idx_map[id] for id in cust_id]

    for this_cust_idx in cust_idx
        println("$this_cust_idx")
    end

    return([("A Customer", "A Product", 1)])
end
