"""
    function ProductReco.fit_transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating}, fn_similarity::Function=cosine_vec)::CollFilteringSVD

Fit model with data and transform the same data with fitted model.

recommnder:     CollFilteringSVD type object
data:           Vector of customer product rating type (CustomerProductRating)
fn_similarity:  Function to calculate similarity between two vectors of ratings
"""

function ProductReco.fit_transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating}, fn_similarity::Function=cosine_vec)::CollFilteringSVD

    try

        # set status
        recommender.fitted = false
        recommender.transformed = false

        # composition of functions where outer function generated dynamically using closure
        recommender = ((recommender -> ProductReco.transform!(recommender, fn_similarity)) ∘ ProductReco.fit!)(recommender, data)

        # set status
        recommender.fitted = true
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.fit_transform!: $err")
        throw(error())
    end
end
