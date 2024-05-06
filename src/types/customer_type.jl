# customer parametric type

# code
struct Customer{T <: Union{String, Int}}

    customer_id::T

end