# customer product rating type

# exports
export Rating
export val

# code
struct Rating

    rating::Float64                 # float needed for SVD

end

"""
    Base.convert(::Type{Rating}, rating::T) where {T <: Union{Int64, Float64}}

Single-line funcition to automatically convert permissible types to Rating.
Overload function in Base module.

first argument:    Rating (user defined type)
rating:            Value to be converted to rating
"""

Base.convert(::Type{Rating}, rating::T) where {T <: Union{Int64, Float64}} = Rating(rating)


"""
    function val(obj::Rating)

Accessor function to get value.

obj:                Rating object
"""

function val(obj::Rating)

    return obj.rating

end

