# product parametric type

# exports
export Product

# code
struct Product{T <: Union{String, Int}}

    product_id::T

end

"""
    function Base.convert(::Type{Product}, product_id::T) where {T <: Union{String, Int}}

Single-line funcition to automatically convert permissible types to Product.
Overload function in Base module.

first argument:    Product (user defined type)
product_id:        ID to be converted to Product type
"""

Base.convert(::Type{Product}, product_id::T) where {T <: Union{String, Int}} = Product(product_id)