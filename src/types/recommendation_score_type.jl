# recommendation score
# higher score treated as stronger recommendation
# integet restricted to 0-100
# this standard is useful when combining recommendations from multiple recommenders

# code
struct RecoScore
    reco_score::Int

    """
        function RecoScore(score::Int)
        
    Constuctor for RecoScore user defined type.
    Check passed integer against valid range. If valid then return constructed object.

    score:  Ingeter score
    """

    function RecoScore(score::Int)
        @assert 0 <= score <= 100
        return new(score)
    end
end

"""
    function Base.convert(::Type{RecoScore}, score::Int)

Single-line funcition to automatically convert integer to RecoScore type.
Overload function in Base module.
Call constructor of RecoScore type with passed integer.

first argument:     RecoScore (user defined type)
score:              Integer to be converted to RecoScore type
"""

Base.convert(::Type{RecoScore}, score::Int) = RecoScore(score)