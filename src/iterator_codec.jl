# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

"""
    abstract type IteratorBasedArrayCodec <: AbstractArrayCodec end

Abstract type for iterator-based array codecs.

Subtypes must implement


and may in some cases need to specialize

* [`encoded_eltype(codec::AbstractArrayCodec, data_eltype::Type)`](@ref)
* [`encoded_size(codec::AbstractArrayCodec, data::AbstractArray)`](@ref)
* [`decoded_eltype(codec::AbstractArrayCodec, encoded_eltype::Type)`](@ref)
* [`decoded_size(codec::AbstractArrayCodec, encoded_data::AbstractArray)::Dims`](@ref)

for increased performance. Specialization of

* [`encode_data!(encoded_data::AbstractVector{UInt8}, codec::AbstractArrayCodec, data::AbstractArray)`](@ref)
* [`decode_data!(data::AbstractVector{UInt8}, codec::AbstractArrayCodec, encoded_data::AbstractArray)`](@ref)
* [`encode_data(codec::AbstractArrayCodec, data::AbstractArray)`](@ref)
* [`decode_data(codec::AbstractArrayCodec, encoded_data::AbstractArray)`](@ref)

should typicall not be necessary.
"""
abstract type IteratorBasedArrayCodec <: AbstractArrayCodec end
export IteratorBasedArrayCodec



function encoded_eltype(codec::IteratorBasedArrayCodec, data_eltype::Type)
    itr = encoding_iterator(codec, data)
    x, state = iterate(itr)
    return typeof(x)
end


function encoded_size(codec::IteratorBasedArrayCodec, data::AbstractArray)::Dims
    itr = encoding_iterator(codec, data)
    n::Int = 0
    @inbounds for x in itr
        n += 1
    end
    return n
end

function encode_data!(encoded_data::AbstractVector{UInt8}, codec::IteratorBasedArrayCodec, data::AbstractArray)
    itr = encoding_iterator(codec, data)
    x, state = iterate(itr)
    last_i = lastindex(encoded_data)
    @inbounds for i in eachindex(encoded_data)
        encoded_data[i] = x
        if i != last_i
            x, state = iterate(itr, state)
        end
    end
    return encoded_data
end


decoded_eltype(codec::IteratorBasedArrayCodec, encoded_eltype::Type) = ...

decoded_size(codec::IteratorBasedArrayCodec, encoded_data::AbstractArray) = ...

decode_data!(data::AbstractVector{UInt8}, codec::IteratorBasedArrayCodec, encoded_data::AbstractArray) = ...
