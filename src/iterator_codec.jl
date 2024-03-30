# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).


function iterator_eltype(f_iterator::Function, data_eltype::Type)
    itr = f_iterator(Vector{data_eltype}())
    x, _ = iterate(itr)
    return typeof(x)
end


function encoded_size(codec::IteratorBasedArrayCodec, data::AbstractVector)::Dims
    itr = encoding_iterator(codec, data)
    n::Int = 0
    @inbounds for x in itr
        n += 1
    end
    return n
end

function encode_data!(encoded_data::AbstractVector{UInt8}, codec::IteratorBasedArrayCodec, data::AbstractVector)
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


"""
    abstract type IteratorBasedArrayCodec <: AbstractArrayCodec end

Abstract type for iterator-based array codecs.

Iterator-based array codecs only support one-dimensional data.

Subtypes of `IteratorBasedArrayCodec` must implement

* [`encoding_iterator(codec::MyIteratorBasedCodec, input)`](@ref)
* [`decoding_iterator(codec::MyIteratorBasedCodec, encoded_input)`](@ref)

and may also profit from specializing

* [`encoded_eltype(codec::MyIteratorBasedCodec, data_eltype::Type)`](@ref)
* [`encoded_size(codec::MyIteratorBasedCodec, data::AbstractVector)`](@ref)
* [`decoded_eltype(codec::MyIteratorBasedCodec, encoded_eltype::Type)`](@ref)
* [`decoded_size(codec::MyIteratorBasedCodec, encoded_data::AbstractVector)::Dims`](@ref)

for increased performance. By default, the iterator-based codec will be run
(discarding the output) to determine the encoded element type and size.
    
Specialization of

* [`encode_data!(encoded_data::AbstractVector{UInt8}, codec::MyIteratorBasedCodec, data::AbstractVector)`](@ref)
* [`decode_data!(data::AbstractVector{UInt8}, codec::MyIteratorBasedCodec, encoded_data::AbstractVector)`](@ref)
* [`encode_data(codec::MyIteratorBasedCodec, data::AbstractVector)`](@ref)
* [`decode_data(codec::MyIteratorBasedCodec, encoded_data::AbstractVector)`](@ref)

should typically not be necessary.
"""
abstract type IteratorBasedArrayCodec <: AbstractArrayCodec end
export IteratorBasedArrayCodec



function encoded_eltype(codec::IteratorBasedArrayCodec, data_eltype::Type)
    itr = encoding_iterator(codec, data)
    x, _ = iterate(itr)
    return typeof(x)
end


function encoded_size(codec::IteratorBasedArrayCodec, data::AbstractVector)::Dims
    itr = encoding_iterator(codec, data)
    n::Int = 0
    @inbounds for x in itr
        n += 1
    end
    return n
end

function encode_data!(encoded_data::AbstractVector{UInt8}, codec::IteratorBasedArrayCodec, data::AbstractVector)
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

decoded_size(codec::IteratorBasedArrayCodec, encoded_data::AbstractVector) = ...

function decode_data!(data::AbstractVector{UInt8}, codec::IteratorBasedArrayCodec, encoded_data::AbstractVector)

end
