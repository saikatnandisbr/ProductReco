# recommendation score
# higher score treated as stronger recommendation
# integet restricted to 0-100
# this standard is useful when combining recommendations from multiple recommenders
struct RecoScore
    reco_score::Int

    """
        function RecoScore(s::Int)
        
    Constuctor for RecoScore user defined type.
    Check passed integer against valid range. If valid then return constructed object.

    s:  Ingeter score
    """

    function RecoScore(s::Int)
        @assert 0 <= s <= 100
        return new(s)
    end
end

"""
    function Base.convert(::Type{RecoScore}, x::Int)

Sinhle-line funcition to automatically convert integer to RecoScore type.
Overload function in Base module.
Call constructor of RecoScore type with passed integer.

first argument:     RecoScore (user defined type)
x:                  Integer to be converted to RecoScore type
"""

Base.convert(::Type{RecoScore}, x::Int) = RecoScore(x)