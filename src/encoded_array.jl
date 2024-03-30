# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).


"""
    AbstractEncodedArray{T,N} <: AbstractArray{T,N}

Abstract type for arrays that store their elements in encoded/compressed form.

In addition to the standard `AbstractArray` API, an `AbstractEncodedArray`
must support the functions

* `EncodedArrays.getcodec(A::EncodedArray)`: Returns the codec.
* `Base.codeunits(A::EncodedArray)`: Returns the internal encoded data
  representation.

Encoded arrays will typically be created via

    A_enc = (codec::AbstractArrayCodec)(A::AbstractArray)

or

    A_enc = AbstractEncodedArray(undef, codec::AbstractArrayCodec)
    append!(A_enc, B::AbstractArray)

Decoding happens via standard array conversion or assignment:

    A_dec = Array(A)
    A_dec = convert(Array,A)
    A_dec = A[:]

    A_dec = Array{T,N}(undef, size(A_enc)...)
    A_dec[:] = A_enc
"""
abstract type AbstractEncodedArray{T,N} <: AbstractArray{T,N} end
export AbstractEncodedArray


import Base.==
==(A::AbstractArray, B::AbstractEncodedArray) = A == Array(B)
==(A::AbstractEncodedArray, B::AbstractArray) = Array(A) == Array(B)
==(A::AbstractEncodedArray, B::AbstractEncodedArray) = Array(A) == Array(B)


"""
    EncodedArrays.getcodec(A::AbstractEncodedArray)::AbstractArrayCodec

Returns the codec used to encode/compress A.
"""
function getcodec end



"""
    EncodedArray{T,N,C,DV} <: AbstractEncodedArray{T,N}

Concrete type for [`AbstractEncodedArray`](@ref)s.

Constructor:

```julia
EncodedArray{T}(
    codec::AbstractArrayCodec,
    size::NTuple{N,Integer},
    encoded::AbstractVector{UInt8}
)
```

Codecs using `EncodedArray` only need to implement
[`EncodedArrays.encode_data!`](@ref) and [`EncodedArrays.decode_data!`](@ref).

If length of the decoded data can be inferred from the encoded data,
a constructor

    EncodedArray{T,N}(codec::MyCodec,encoded::AbstractVector{UInt8})

should also be defined. By default, two `EncodedArray`s that have the same
codec and size are assumed to be equal if and only if their code units are
equal.

Generic methods for the rest of the [`AbstractEncodedArray`](@ref) API are
already provided for `EncodedArray`. 
"""
struct EncodedArray{T,N,C<:AbstractArrayCodec,DV<:AbstractVector{UInt8}} <: AbstractEncodedArray{T,N}
    codec::C
    size::NTuple{N,Int}
    encoded::DV
end
export EncodedArray


EncodedArray{T}(
    codec::AbstractArrayCodec,
    size::NTuple{N,Integer},
    encoded::AbstractVector{UInt8}
) where {T,N} = EncodedArray{T, N, typeof(codec),typeof(encoded)}(codec, size, encoded)

EncodedArray{T}(
    codec::AbstractArrayCodec,
    length::Integer,
    encoded::AbstractVector{UInt8}
) where {T} = EncodedArray{T, typeof(codec),typeof(encoded)}(codec, (len,), encoded)

EncodedArray{T,N,C,DV}(A::EncodedArray{T,N,C}) where {T,N,C,DV} = EncodedArray{T,N,C,DV}(A.codec, A.size, A.encoded)
Base.convert(::Type{EncodedArray{T,N,C,DV}}, A::EncodedArray{T,N,C}) where {T,N,C,DV} = EncodedArray{T,N,C,DV}(A)


@inline Base.size(A::EncodedArray) = A.size
@inline getcodec(A::EncodedArray) = A.codec
@inline Base.codeunits(A::EncodedArray) = A.encoded

# ToDo: Base.iscontiguous

function Base.Array{T,N}(A::EncodedArray{U,N}) where {T,N,U}
    B = Array{T,N}(undef, size(A)...)
    decode_data!(B, getcodec(A), codeunits(A))
end

Base.Array{T}(A::EncodedArray{U,N}) where {T,N,U} = Array{T,N}(A)
Base.Array(A::EncodedArray{T,N}) where {T,N} = Array{T,N}(A)

Base.Vector(A::EncodedArray{T,1}) where {T} = Array{T,1}(A)
Base.Matrix(A::EncodedArray{T,2}) where {T} = Array{T,2}(A)

Base.convert(::Type{Array{T,N}}, A::EncodedArray) where {T,N} = Array{T,N}(A)
Base.convert(::Type{Array{T}}, A::EncodedArray) where {T} = Array{T}(A)
Base.convert(::Type{Array}, A::EncodedArray) = Array(A)

Base.convert(::Type{Vector}, A::EncodedArray) = Vector(A)
Base.convert(::Type{Matrix}, A::EncodedArray) = Matrix(A)


Base.IndexStyle(A::EncodedArray) = IndexLinear()


function _getindex(A::EncodedArray, idxs::AbstractVector{Int})
    B = collect(A)
    if idxs == eachindex(IndexLinear(), A)
        B
    else
        B[idxs]
    end
end


_getindex(A::EncodedArray, i::Int) = collect(A)[i]


Base.@propagate_inbounds Base.getindex(A::EncodedArray, idxs) =
    _getindex(A, Base.to_indices(A, (idxs,))...)


@inline function _setindex!(A::AbstractArray, B::EncodedArray, idxs::AbstractVector{Int})
    @boundscheck let n = length(idxs), len_B = length(eachindex(B))
        n == len_B || Base.throw_setindex_mismatch(B, (n,))
    end

    if idxs == eachindex(A) || idxs == axes(A)
        decode_data!(A, getcodec(B), codeunits(B))
    else
        decode_data!(view(A, idxs), getcodec(B), codeunits(B))
    end

    A
end

Base.@propagate_inbounds function Base.setindex!(A::AbstractArray, B::EncodedArray, idxs::Colon)
    _setindex!(A, B, Base.to_indices(A, (idxs,))...)
end

@inline Base.@propagate_inbounds function Base.setindex!(A::Array, B::EncodedArray, idxs::AbstractVector{Int})
    @boundscheck checkbounds(A, idxs)
    _setindex!(A, B, Base.to_indices(A, (idxs,))...)
end


function _append!(A::AbstractVector, B::EncodedArray)
    n = length(eachindex(B))
    from = lastindex(A) + 1
    to = lastindex(A) + n
    resize!(A, to + 1 - firstindex(A))
    A[from:to] = B
    A
end

Base.append!(A::AbstractVector, B::EncodedArray) = _append!(A, B)
Base.append!(A::Vector, B::EncodedArray) = _append!(A, B)

# # ToDo (compatible with ElasticArrays.ElasticArray): 
# Base.append!(A::AbstractArray{T,N}, B::EncodedArray) where {T,N} = ...


@inline function Base.copyto!(dest::AbstractArray, src::EncodedArray)
    @boundscheck if length(eachindex(dest)) < length(eachindex(src))
        throw(BoundsError())
    end
    decode_data!(dest, getcodec(src), codeunits(src))
end

# # ToDo:
# Base.copyto!(dest::AbstractArray, destoffs, src::EncodedArray, srcoffs, N) = ...


import Base.==
function ==(A::EncodedArray, B::EncodedArray)
    if getcodec(A) == getcodec(B) && size(A) == size(B)
        codeunits(A) == codeunits(B)
    else
        Array(A) == Array(B)
    end
end


"""
    VectorOfEncodedArrays{T,N,...}

A vector of encoded arrays.

The code units of all entries are stored in contiguous fashion using
an `ArraysOfArray.VectorOfArrays`. All element arrays are encoded using the
same codec.
"""
struct VectorOfEncodedArrays{
    T, N,
    C <: AbstractArrayCodec,
    VS <: AbstractVector{<:NTuple{N,<:Integer}},
    VOA <: VectorOfArrays
} <: AbstractVector{EncodedArray{T,N,C,Array{UInt8,1}}}
    codec::C
    innersizes::VS
    encoded::VOA
end

export VectorOfEncodedArrays

VectorOfEncodedArrays{T}(codec::AbstractArrayCodec, innersizes::AbstractVector{<:NTuple{N,<:Integer}}, encoded::VectorOfArrays) where {T,N} =
    VectorOfEncodedArrays{T,N,typeof(codec),typeof(innersizes),typeof(encoded)}(codec, innersizes, encoded)


@inline Base.size(A::VectorOfEncodedArrays) = size(A.encoded)

@inline Base.getindex(A::VectorOfEncodedArrays{T}, i::Int) where T =
    EncodedArray{T}(A.codec, A.innersizes[i], A.encoded[i])

@inline Base.getindex(A::VectorOfEncodedArrays{T}, idxs::Union{AbstractArray,Colon}) where T = 
    VectorOfEncodedArrays{T}(A.codec, A.innersizes[idxs], A.encoded[idxs])

@inline Base.IndexStyle(::Type{<:VectorOfEncodedArrays}) = IndexLinear()


const BroadcastedEncodeVectorOfArrays{T,N,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    <:Base.Broadcast.AbstractArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(|>),
    <:Tuple{
        VectorOfArrays{T,N},
        Union{Tuple{C},Ref{C}}
    }
}


@inline _get_1st_or_ith(A, i::Int) = (length(A) == 1) ? A[1] : A[i]

function _bcast_enc_impl(::Type{T}, ::Val{N}, ::Type{C}, data_arg, codec_arg) where {T,N,C}
    idxs_tuple = Base.Broadcast.combine_axes(data_arg, codec_arg)
    @assert length(idxs_tuple) == 1
    idxs = idxs_tuple[1]

    codec = only(codec_arg)
    n = length(idxs)
    size_vec = Vector{NTuple{N,Int}}(undef, n)
    encoded_vec = VectorOfVectors{UInt8}()

    sizehint!(encoded_vec.elem_ptr, n + 1)
    sizehint!(encoded_vec.kernel_size, n)

    for i in idxs
        data = _get_1st_or_ith(data_arg, i)

        size_vec[i] = size(data)

        # ToDo: Improve, eliminate temporary memory allocation:
        tmp_encoded = encode_data!(Vector{UInt8}(), codec, data)
        push!(encoded_vec, tmp_encoded)
    end

    return VectorOfEncodedArrays{T}(codec, size_vec, encoded_vec)
end

function Base.copy(instance::BroadcastedEncodeVectorOfArrays{T,N,C}) where {T,N,C}
    data_arg = instance.args[1]
    codec_arg = instance.args[2]
    _bcast_enc_impl(T, Val{N}(), C, data_arg, codec_arg)
end


const BroadcastedDecodeVectorOfArrays{T,M,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    Base.Broadcast.DefaultArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(collect),
    <:Tuple{VectorOfEncodedArrays{T,M,C}}
}

function _bcast_dec_impl(::Type{T}, ::Val{N}, ::Type{C}, encoded_data) where {T,N,C}
    result = VectorOfArrays{T,N}()
    @inbounds for i in eachindex(encoded_data)
        x = encoded_data[i]
        push!(result, Fill(typemax(T), length(x)))
        copyto!(last(result), x)
    end
    result
end

function Base.copy(instance::BroadcastedDecodeVectorOfArrays{T,N,C}) where {T,N,C}
    _bcast_dec_impl(T, Val{N}(), C, instance.args[1])
end



# ToDo: SerialArrayCodec with decode_next, encode_next!, pos_type(codec),
#       finalize_codeunits!

# ToDo: Custom broadcasting over encoded array.



"""
    VectorOfEncodedSimilarArrays{T,M,C,...}

A vector of encoded arrays that have the same original size.

The code units of all entries are stored in contiguous fashion using
an `ArraysOfArray.VectorOfArrays`. All element arrays are encoded using the
same codec.
"""
struct VectorOfEncodedSimilarArrays{
    T, M,
    C <: AbstractArrayCodec,
    VOA <: VectorOfArrays
} <: AbstractArrayOfSimilarArrays{T,M,1}
    codec::C
    innersize::Dims{M}
    encoded::VOA
end

export VectorOfEncodedSimilarArrays

VectorOfEncodedSimilarArrays{T}(codec::AbstractArrayCodec, innersize::Dims{M}, encoded::VectorOfArrays) where {T,M} =
    VectorOfEncodedSimilarArrays{T,M,typeof(codec),typeof(encoded)}(codec, innersize, encoded)

@inline Base.size(A::VectorOfEncodedSimilarArrays) = size(A.encoded)

@inline Base.getindex(A::VectorOfEncodedSimilarArrays{T}, i::Int) where T =
    EncodedArray{T}(A.codec, A.innersize, A.encoded[i])

@inline Base.getindex(A::VectorOfEncodedSimilarArrays{T}, idxs::Union{AbstractArray,Colon}) where T = 
    VectorOfEncodedSimilarArrays{T}(A.codec, A.innersize, A.encoded[idxs])

@inline Base.IndexStyle(::Type{<:VectorOfEncodedSimilarArrays}) = IndexLinear()

ArraysOfArrays.innersize(A::VectorOfEncodedSimilarArrays) = A.innersize


const BroadcastedEncodeVectorOfSimilarArrays{T,M,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    <:Base.Broadcast.AbstractArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(|>),
    <:Tuple{
        AbstractArrayOfSimilarArrays{T,M,1},
        Union{Tuple{C},Ref{C}}
    }
}

function Base.copy(instance::BroadcastedEncodeVectorOfSimilarArrays{T,M,C}) where {T,M,C}
    data_arg = instance.args[1]
    codec_arg = instance.args[2]
    voea = _bcast_enc_impl(T, Val{M}(), C, data_arg, codec_arg)
    codec = voea.codec
    encoded = voea.encoded
    VectorOfEncodedSimilarArrays{T}(codec, innersize(data_arg), encoded)
end



const BroadcastedDecodeVectorOfSimilarArrays{T,M,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    Base.Broadcast.DefaultArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(collect),
    <:Tuple{VectorOfEncodedSimilarArrays{T,M,C}}
}

function _decode_data_noret!(args...)
    decode_data!(args...)
    return nothing
end

function _bcast_dec_impl(encoded_arrays::VectorOfEncodedSimilarArrays{T,M,C}) where {T,M,C}
    codec = encoded_arrays.codec
    elsz = encoded_arrays.innersize
    encoded_data = encoded_arrays.encoded
    n = length(encoded_data)
    decoded_data = similar(flatview(encoded_data), T, elsz..., n)
    result = VectorOfSimilarArrays(decoded_data)
    _decode_data_noret!.(result, Ref(codec), encoded_data)
    return result
end

function Base.copy(instance::BroadcastedDecodeVectorOfSimilarArrays)
    _bcast_dec_impl(instance.args[1])    
end



"""
    as_encoded(codec::AbstractArrayCodec, A::AbstractArray{T})::AbstractEncodedArray

Encode `A` using `codec` and return an [`AbstractEncodedArray`](@ref). The
default implementation returns an [`EncodedArray`](@ref).
"""
function as_encoded(codec::AbstractArrayCodec, A::AbstractArray{T}) where T
    EncodedArray{T}(codec, size(A), encode(data(codec, A)))
end
