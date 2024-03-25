# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

"""
    abstract type AbstractArrayCodec <: Codecs.Codec end

Abstract type for arrays codecs.

Subtypes must implement the [`AbstractEncodedArray`](@ref) API.
Most coded should use [`EncodedArray`](@ref) as the concrete subtype of
`AbstractArrayCodec`. Codecs that use a custom subtype of
`AbstractEncodedArray` must implement

    EncodedArrays.encarraytype(::Type{<:AbstractArrayCodec},::Type{<:AbstractArray{T,N}})::Type{<:AbstractEncodedArray{T,N}}
"""
abstract type AbstractArrayCodec end
export AbstractArrayCodec



"""
    encode_data(codec::AbstractArrayCodec, data::AbstractArray)

Returns the encoded (low-level) representation of `data` using `codec`.

Use [`encoded_array`](@ref) to return an [`AbstractEncodedArray`](@ref).

See also [`encode_data!`](@ref), [`decode_data`](@ref) and
[`decode_data!`](@ref).
"""
function encode_data end
export encode_data

"""
    encode_data(codec::AbstractArrayCodec)

Equivalent to `data -> encode_data(codec, data)`.
"""
encode_data(codec::AbstractArrayCodec) = Base.Fix1(encode_data, codec)



"""
    decode_data(codec::AbstractArrayCodec, encoded_data::AbstractArray)

Decode the (low-level) `encoded_data` and return the original data.

See also [`decode_data!`](@ref), [`encode_data`](@ref) and
[`encode_data`](@ref).
"""
function decode_data end
export decode_data

"""
    encoded_data(codec::AbstractArrayCodec)

Equivalent to `data -> decode_data(codec, encoded_data)`.
"""
decode_data(codec::AbstractArrayCodec) = Base.Fix1(decode_data, codec)


"""
    decoded_shape(codec::AbstractArrayCodec, encoded_data::AbstractArray)
"""


# Make AbstractArrayCodec behave as a Scalar for broadcasting
@inline Base.Broadcast.broadcastable(codec::AbstractArrayCodec) = (codec,)


"""
    encode_data!(encoded::AbstractVector{UInt8}, codec::AbstractArrayCodec, data::AbstractArray)

Will resize `encoded` as necessary to fit the encoded data.

Returns `encoded`.
"""
function encode_data! end


"""
    decode_data!(data::AbstractArray, codec::AbstractArrayCodec, encoded::AbstractVector{UInt8})

Depending on `codec`, may or may not resize `decoded` to fit the size of the
decoded data. Codecs may require `decoded` to be of correct size (e.g. to
improved performance or when the size/shape of the decoded data cannot be
easily inferred from the encoded data.

Returns `data`.
"""
function decode_data! end
