# recommendation score
# integet restricted to 0-100
# higher score treated as stronger recommendation
struct RecoScore
    reco_score::Int

    # make sure that score is an integer between 0-100
    # this standard makes it easier to create composite score when multiple recommenders are combined
    function RecoScore(s::Int)
        @assert 0 <= s <= 100
        return new(s)
    end
end

# automatically convert integer to RecoScore type
Base.convert(::Type{RecoScore}, x::Int) = RecoScore(x)