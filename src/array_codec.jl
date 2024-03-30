# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

"""
    abstract type AbstractArrayCodec end

Abstract type for arrays codecs.

Subtypes of `AbstractArrayCodec` must implement

* [`encoded_eltype(codec::MyArrayCodec, data_eltype::Type)`](@ref)
* [`encoded_size(codec::MyArrayCodec, data::AbstractArray)`](@ref)
* [`encode_data!(encoded_data::AbstractVector{UInt8}, codec::MyArrayCodec, data::AbstractArray)`](@ref)
* [`decoded_eltype(codec::MyArrayCodec, encoded_eltype::Type)`](@ref)
* [`decoded_size(codec::MyArrayCodec, encoded_data::AbstractArray)::Dims`](@ref)
* [`decode_data!(data::AbstractVector{UInt8}, codec::MyArrayCodec, encoded_data::AbstractArray)`](@ref)

and may in some cases need to specialize

* [`encode_data(codec::MyArrayCodec, data::AbstractArray)`](@ref)
* [`decode_data(codec::MyArrayCodec, encoded_data::AbstractArray)`](@ref)
"""
abstract type AbstractArrayCodec end
export AbstractArrayCodec

# Make AbstractArrayCodec behave as a Scalar for broadcasting
@inline Base.Broadcast.broadcastable(codec::AbstractArrayCodec) = Ref(codec)


"""
    encoded_eltype(codec::AbstractArrayCodec, data_eltype::Type)::Type

Returns the element type of the encoded data that will be produced by encoding
data with element type `data_eltype` using `codec`.

See also [`encoded_size`](@ref) and [`decoded_eltype`](@ref).
"""
function encoded_eltype end
export encoded_eltype


"""
    encoded_size(codec::AbstractArrayCodec, data::AbstractArray)::Dims

Returns the size of the encoded data that will be produced by encoding `data`
using `codec`.

See also [`encoded_eltype`](@ref) and [`decoded_size`](@ref).
"""
function encoded_size end
export encoded_size


"""
    encode_data!(encoded_data::AbstractVector{UInt8}, codec::AbstractArrayCodec, data::AbstractArray)

Encode `data`, stores the result in `encoded_data` and return `encoded_data`.

Use

```julia
encoded_data = similar(data, encoded_eltype(codec, eltype(data)), encoded_size(codec, data))
```

or similar to create an `encoded_data` array of the right element type and size.
"""
function encode_data! end


"""
    encode_data(codec::AbstractArrayCodec, data::AbstractArray)

Returns the encoded (low-level) representation of `data` using `codec`.

The returned encoded data must have element type
`encoded_eltype(codec, eltype(data))` and size
`size(encode_data(codec, data))`.

Use [`encoded_array`](@ref) to generate an [`AbstractEncodedArray`](@ref)
instead of just the encoded data.

See also [`encode_data!`](@ref), [`decode_data`](@ref) and
[`decode_data!`](@ref).
"""
function encode_data end
export encode_data

function encode_data(codec::AbstractArrayCodec, data::AbstractArray)
    encoded_data = similar(data, encoded_eltype(codec, eltype(data)), encoded_size(codec, data))
    return encode_data!(encoded_data, codec, data)
end

"""
    encode_data(codec::AbstractArrayCodec)

Returns a function equivalent to
`data -> encode_data(codec, data)`.
"""
encode_data(codec::AbstractArrayCodec) = Base.Fix1(encode_data, codec)



"""
    decoded_eltype(codec::AbstractArrayCodec, encoded_eltype::Type)

Returns the element type of the decoded data that will be produced by
decoding data with encoded data type `encoded_eltype` using `codec`.

See also [`decoded_size`](@ref) and [`encoded_eltype`](@ref).
"""
function decoded_eltype end
export decoded_eltype


"""
    decoded_size(codec::AbstractArrayCodec, encoded_data::AbstractArray)::Dims

Returns the size of the decoded data that will be produced by decoding
`encoded_data` using `codec`.

The returned size must equal `size(decode_data(codec, encoded_data))`, but the
implementation must *not* use `decode_data`.

See also [`encoded_size`](@ref) and [`decoded_eltype`](@ref).
"""
function decoded_size end
export decoded_size


"""
    decode_data!(data::AbstractVector{UInt8}, codec::AbstractArrayCodec, encoded_data::AbstractArray)

Decodes `encoded_data` using `codec`, stores the result in `data` and return `data`.

Use

```julia
data = similar(encoded_data, decoded_eltype(codec, eltype(encoded_data)), decoded_size(codec, encoded_data))
```

or similar to create an `data` array of the right element type and size.
"""
function decode_data! end


"""
    decode_data(codec::AbstractArrayCodec, encoded_data::AbstractArray)

Returns the decoded (low-level) representation of `encoded_data` using `codec`.

The returned decoced data must have element type
`decoded_eltype(codec, eltype(encoded_data))` and size
`size(encode_data(codec, encoded_data))`.

See also [`decode_data!`](@ref), [`decode_data`](@ref) and
[`decode_data!`](@ref).
"""
function decode_data end
export decode_data

function decode_data(codec::AbstractArrayCodec, encoded_data::AbstractArray)
    data = similar(encoded_data, decoded_eltype(codec, eltype(encoded_data)), decoded_size(codec, encoded_data))
    return decode_data!(data, codec, encoded_data)
end

"""
    decode_data(codec::AbstractArrayCodec)

Returns a function equivalent to
`encoded_data -> decode_data(codec, encoded_data)`.
"""
decode_data(codec::AbstractArrayCodec) = Base.Fix1(decode_data, codec)
