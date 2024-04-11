# recommendation score
# higher score treated as stronger recommendation
# integet restricted to 0-100
# this standard is useful when combining recommendations from multiple recommenders
struct RecoScore
    reco_score::Int

    # make sure that score is an integer between 0-100
    function RecoScore(s::Int)
        @assert 0 <= s <= 100
        return new(s)
    end
end

# automatically convert integer to RecoScore type
Base.convert(::Type{RecoScore}, x::Int) = RecoScore(x)