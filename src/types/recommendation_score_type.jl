# recommendation score
# integet restricted to 0-100
# higher score treated as stronger recommendation
struct RecoScore
    reco_score::Int

    function RecoScore(s)
        @assert 0 <= s <= 100
        return new(s)
    end
end