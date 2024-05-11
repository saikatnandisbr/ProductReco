# customer product rating parametric type

# exports
export Rating

# code
struct Rating{T <: Union{Int64, Float64}}

    rating::T

end

"""
    function Base.convert(::Type{Rating}, rating::T) where {T <: Union{Int64, Float64}}

Single-line funcition to automatically convert permissible types to Rating.
Overload function in Base module.

first argument:    Rating (user defined type)
rating:            Value to be converted to Rating type
"""

Base.convert(::Type{Rating}, rating::T) where {T <: Union{Int64, Float64}} = Rating(rating)