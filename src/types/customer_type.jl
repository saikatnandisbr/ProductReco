# customer parametric type

# exports
export Customer

# code
struct Customer{T <: Union{String, Int}}

    customer_id::T

end

"""
    function Base.convert(::Type{Customer}, customer_id::T) where {T <: Union{String, Int}}

Single-line funcition to automatically convert permissible types to Customer.
Overload function in Base module.
Call constructor of Customer type with passed value.

first argument:     Customer (user defined type)
customer_id:        ID to be converted to Customer type
"""

Base.convert(::Type{Customer}, customer_id::T) where {T <: Union{String, Int}} = Customer(customer_id)