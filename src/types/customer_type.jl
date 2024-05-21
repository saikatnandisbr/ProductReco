# customer parametric type

# exports
export Customer
export id

# code
struct Customer{T <: Union{String, Int64}}

    customer_id::T

end


"""
    function Base.convert(::Type{Customer}, customer_id::T) where {T <: Union{AbstractString, Int64}}

Single-line funcition to automatically convert permissible types to Customer.
Overload function in Base module.

first argument:     Customer (user defined type)
customer_id:        ID to be converted to Customer type
"""

Base.convert(::Type{Customer}, customer_id::T) where {T <: Union{AbstractString, Int64}} = Customer(customer_id)

"""
    function id(obj::Customer)

Accessor function to get id.

obj:                Customer object
"""

function id(obj::Customer)
    return obj.customer_id
end
