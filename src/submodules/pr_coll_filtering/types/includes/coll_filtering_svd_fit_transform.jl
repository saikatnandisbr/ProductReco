"""
    function ProductReco.fit_transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

Fit model with data and transform the same data with fitted model.

recommnder:     CollFilteringSVD type object
data:           Vector of customer product rating type (CustomerProductRating)
"""

function ProductReco.fit_transform!(recommender::CollFilteringSVD, data::Vector{CustomerProductRating})::CollFilteringSVD

    try

        # set status
        recommender.fitted = false
        recommender.transformed = false

        recommender = (ProductReco.transform! ∘ ProductReco.fit!)(recommender, data)

        # set status
        recommender.fitted = true
        recommender.transformed = true

        return recommender

    catch err
        println("ProductReco.fit_transform!: $err")
        throw(error())
    end
end
