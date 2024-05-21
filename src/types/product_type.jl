# product parametric type

# exports
export Product
export id

# code
struct Product{T <: Union{String, Int64}}

    product_id::T

end

"""
    function Base.convert(::Type{Product}, product_id::T) where {T <: Union{AbstractString, Int64}}

Single-line funcition to automatically convert permissible types to Product.
Overload function in Base module.

first argument:    Product (user defined type)
product_id:        ID to be converted to Product type
"""

Base.convert(::Type{Product}, product_id::T) where {T <: Union{AbstractString, Int64}} = Product(product_id)

"""
    function id(obj::Product)

Accessor function to get id.

obj:                Product object
"""

function id(obj::Product)
    return obj.product_id
end