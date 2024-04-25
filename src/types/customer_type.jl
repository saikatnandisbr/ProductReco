# customer parametric type
struct Customer{T <: Union{String, Int}}

    customer_id::T

end