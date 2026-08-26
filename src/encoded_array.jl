# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).


"""
    abstract type AbstractArrayCodec

Abstract type for array codecs.

Most codecs can use [`EncodedArray`](@ref) as their encoded-array type and
only need to implement [`EncodedArrays.encode_data!`](@ref) and
[`EncodedArrays.decode_data!`](@ref). Codecs that use a custom subtype of
[`AbstractEncodedArray`](@ref) must implement its full API.
"""
abstract type AbstractArrayCodec end
export AbstractArrayCodec


import Base.|>

"""
    |>(A::AbstractArray{T}, codec::AbstractArrayCodec)::AbstractEncodedArray

Encode `A` using `codec` and return an [`AbstractEncodedArray`](@ref). The
default implementation returns an [`EncodedArray`](@ref).
"""
function |>(A::AbstractArray{T}, codec::AbstractArrayCodec) where T
    encoded = Vector{UInt8}()
    encode_data!(encoded, codec, A)
    EncodedArray{T}(codec, size(A), encoded)
end


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

Depending on `codec`, may or may not resize `data` to fit the size of the
decoded data. Codecs may require `data` to be of correct size (e.g. to
improve performance or when the size/shape of the decoded data cannot be
easily inferred from the encoded data).

Returns `data`.
"""
function decode_data! end



"""
    AbstractEncodedArray{T,N} <: AbstractArray{T,N}

Abstract type for arrays that store their elements in encoded/compressed form.

In addition to the standard `AbstractArray` API, an `AbstractEncodedArray`
must support the functions

* `EncodedArrays.getcodec(A::AbstractEncodedArray)`: Returns the codec.
* `Base.codeunits(A::AbstractEncodedArray)`: Returns the internal encoded
  data representation.

Encoded arrays will typically be created via

    A_enc = A |> codec

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
    len::Integer,
    encoded::AbstractVector{UInt8}
) where {T} = EncodedArray{T}(codec, (len,), encoded)

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

Base.collect(A::EncodedArray) = Array(A)

Base.Vector(A::EncodedArray{T,1}) where {T} = Array{T,1}(A)
Base.Matrix(A::EncodedArray{T,2}) where {T} = Array{T,2}(A)

Base.convert(::Type{Array{T,N}}, A::EncodedArray) where {T,N} = Array{T,N}(A)
Base.convert(::Type{Array{T}}, A::EncodedArray) where {T} = Array{T}(A)
Base.convert(::Type{Array}, A::EncodedArray) = Array(A)

Base.convert(::Type{Vector}, A::EncodedArray) = Vector(A)
Base.convert(::Type{Matrix}, A::EncodedArray) = Matrix(A)


Base.IndexStyle(::Type{<:EncodedArray}) = IndexLinear()


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

The code units of all entries are stored in contiguous fashion using an
`ArraysOfArrays.PartsView`. All element arrays are encoded using the same
codec.

Constructors:

```julia
VectorOfEncodedArrays{T,N}(codec::AbstractArrayCodec)
VectorOfEncodedArrays{T}(codec::AbstractArrayCodec, innersizes::AbstractVector{<:Dims{N}}, encoded::PartsView{UInt8})
```

`A .|> codec` encodes a vector of arrays `A`, `collect.(A_enc)` decodes it
into a `VectorOfArrays` again. `push!`, `append!` and `vcat` encode and add
further arrays.

`ArraysOfArrays.fused` decodes all element arrays into a flat vector and
`ArraysOfArrays.getsplitmode` describes their layout, so
`splitup(fused(A_enc), getsplitmode(A_enc))` is the decoded vector of
arrays. Operations based on these, like `flatview`, `innersum` or `mapat`,
decode all elements and so allocate.
"""
struct VectorOfEncodedArrays{
    T, N,
    C <: AbstractArrayCodec,
    VS <: AbstractVector{<:NTuple{N,<:Integer}},
    VOA <: PartsView{UInt8},
    DV <: AbstractVector{UInt8}
} <: AbstractVector{EncodedArray{T,N,C,DV}}
    codec::C
    innersizes::VS
    encoded::VOA
end

export VectorOfEncodedArrays

VectorOfEncodedArrays{T}(codec::AbstractArrayCodec, innersizes::AbstractVector{<:NTuple{N,<:Integer}}, encoded::PartsView{UInt8}) where {T,N} =
    VectorOfEncodedArrays{T,N,typeof(codec),typeof(innersizes),typeof(encoded),eltype(encoded)}(codec, innersizes, encoded)

VectorOfEncodedArrays{T,N}(codec::AbstractArrayCodec) where {T,N} =
    VectorOfEncodedArrays{T}(codec, Vector{Dims{N}}(), PartsView{UInt8}())

Base.empty(A::VectorOfEncodedArrays{T,N}) where {T,N} = VectorOfEncodedArrays{T,N}(A.codec)


@inline Base.size(A::VectorOfEncodedArrays) = size(A.encoded)

@inline Base.getindex(A::VectorOfEncodedArrays{T}, i::Int) where T =
    EncodedArray{T}(A.codec, A.innersizes[i], A.encoded[i])

@inline Base.getindex(A::VectorOfEncodedArrays{T}, idxs::Union{AbstractArray,Colon}) where T = 
    VectorOfEncodedArrays{T}(A.codec, A.innersizes[idxs], A.encoded[idxs])

@inline Base.IndexStyle(::Type{<:VectorOfEncodedArrays}) = IndexLinear()


ArraysOfArrays.innersizes(A::VectorOfEncodedArrays) = A.innersizes

ArraysOfArrays.innerlengths(A::VectorOfEncodedArrays) = prod.(A.innersizes)

function ArraysOfArrays.getsplitmode(A::VectorOfEncodedArrays{T,N}) where {T,N}
    elem_ptr = cumsum(vcat(1, innerlengths(A)))
    kernel_size = map(s -> Base.front(Dims{N}(s)), A.innersizes)
    SplitParts(elem_ptr, kernel_size)
end

function _decoded(A::VectorOfEncodedArrays{T}) where T
    result = splitup(Vector{T}(undef, sum(innerlengths(A))), getsplitmode(A))
    for i in eachindex(A)
        decode_data!(result[i], A.codec, A.encoded[i])
    end
    result
end

ArraysOfArrays.fused(A::VectorOfEncodedArrays) = fused(_decoded(A))

ArraysOfArrays.flatview(A::VectorOfEncodedArrays) = fused(A)


function _push_encoded!(A::VectorOfEncodedArrays, buf::AbstractVector{UInt8}, x::AbstractArray)
    push!(A.innersizes, size(x))
    push!(A.encoded, encode_data!(buf, A.codec, x))
    A
end

function _require_same_codec(A, Bs)
    all(B -> B.codec == A.codec, Bs) || throw(ArgumentError("Can't concatenate vectors of arrays encoded with different codecs"))
    nothing
end

function Base.vcat(A::VectorOfEncodedArrays{T,N}, Bs::VectorOfEncodedArrays{T,N}...) where {T,N}
    _require_same_codec(A, Bs)
    VectorOfEncodedArrays{T}(A.codec, vcat(A.innersizes, map(B -> B.innersizes, Bs)...), vcat(A.encoded, map(B -> B.encoded, Bs)...))
end

function ==(A::VectorOfEncodedArrays, B::VectorOfEncodedArrays)
    if A.codec == B.codec
        A.innersizes == B.innersizes && A.encoded == B.encoded
    else
        invoke(==, Tuple{AbstractArray,AbstractArray}, A, B)
    end
end


const BroadcastedEncodeVectorOfArrays{T,N,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    NestedArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(|>),
    <:Tuple{
        VectorOfArrays{T,N},
        Union{Tuple{C},Ref{C}}
    }
}

Base.copy(instance::BroadcastedEncodeVectorOfArrays{T,N,C}) where {T,N,C} =
    append!(VectorOfEncodedArrays{T,N}(only(instance.args[2])), instance.args[1])


const BroadcastedDecodeVectorOfArrays{T,M,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    Base.Broadcast.DefaultArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(collect),
    <:Tuple{VectorOfEncodedArrays{T,M,C}}
}

Base.copy(instance::BroadcastedDecodeVectorOfArrays) = _decoded(instance.args[1])



# ToDo: SerialArrayCodec with decode_next, encode_next!, pos_type(codec),
#       finalize_codeunits!

# ToDo: Custom broadcasting over encoded array.



"""
    VectorOfEncodedSimilarArrays{T,M,C,...}

A vector of encoded arrays that have the same original size.

The code units of all entries are stored in contiguous fashion using an
`ArraysOfArrays.PartsView`. All element arrays are encoded using the same
codec.

Constructors:

```julia
VectorOfEncodedSimilarArrays{T}(codec::AbstractArrayCodec, innersize::Dims{M})
VectorOfEncodedSimilarArrays{T}(codec::AbstractArrayCodec, innersize::Dims{M}, encoded::PartsView{UInt8})
```

`A .|> codec` encodes a vector of similar arrays `A`, `collect.(A_enc)`
decodes it into a `VectorOfSimilarArrays` again. `push!`, `append!` and
`vcat` encode and add further arrays of the same size.

`ArraysOfArrays.fused` decodes all element arrays, so operations based on
it, like `flatview`, `stack`, `parent`, comparisons, `innersum` or `mapat`,
allocate.
"""
struct VectorOfEncodedSimilarArrays{
    T, M,
    C <: AbstractArrayCodec,
    VOA <: PartsView{UInt8},
    DV <: AbstractVector{UInt8}
} <: AbstractVectorOfSimilarArrays{T,M,EncodedArray{T,M,C,DV}}
    codec::C
    innersize::Dims{M}
    encoded::VOA
end

export VectorOfEncodedSimilarArrays

VectorOfEncodedSimilarArrays{T}(codec::AbstractArrayCodec, innersize::Dims{M}, encoded::PartsView{UInt8}) where {T,M} =
    VectorOfEncodedSimilarArrays{T,M,typeof(codec),typeof(encoded),eltype(encoded)}(codec, innersize, encoded)

VectorOfEncodedSimilarArrays{T}(codec::AbstractArrayCodec, innersize::Dims{M}) where {T,M} =
    VectorOfEncodedSimilarArrays{T}(codec, innersize, PartsView{UInt8}())

Base.empty(A::VectorOfEncodedSimilarArrays{T}) where T = VectorOfEncodedSimilarArrays{T}(A.codec, A.innersize)


@inline Base.size(A::VectorOfEncodedSimilarArrays) = size(A.encoded)

@inline Base.getindex(A::VectorOfEncodedSimilarArrays{T}, i::Int) where T =
    EncodedArray{T}(A.codec, A.innersize, A.encoded[i])

@inline Base.getindex(A::VectorOfEncodedSimilarArrays{T}, idxs::Union{AbstractArray,Colon}) where T =
    VectorOfEncodedSimilarArrays{T}(A.codec, A.innersize, A.encoded[idxs])

@inline Base.IndexStyle(::Type{<:VectorOfEncodedSimilarArrays}) = IndexLinear()


ArraysOfArrays.innersize(A::VectorOfEncodedSimilarArrays) = A.innersize

function _decoded(A::VectorOfEncodedSimilarArrays{T}) where T
    result = VectorOfSimilarArrays(Array{T}(undef, A.innersize..., length(A)))
    for i in eachindex(A)
        decode_data!(result[i], A.codec, A.encoded[i])
    end
    result
end

ArraysOfArrays.fused(A::VectorOfEncodedSimilarArrays) = fused(_decoded(A))


function _push_encoded!(A::VectorOfEncodedSimilarArrays, buf::AbstractVector{UInt8}, x::AbstractArray)
    size(x) == A.innersize || throw(DimensionMismatch("Can't add array of size $(size(x)) to vector of encoded arrays of size $(A.innersize)"))
    push!(A.encoded, encode_data!(buf, A.codec, x))
    A
end

function Base.vcat(A::VectorOfEncodedSimilarArrays{T,M}, Bs::VectorOfEncodedSimilarArrays{T,M}...) where {T,M}
    _require_same_codec(A, Bs)
    all(B -> B.innersize == A.innersize, Bs) || throw(DimensionMismatch("Can't concatenate vectors of encoded arrays of different sizes"))
    VectorOfEncodedSimilarArrays{T}(A.codec, A.innersize, vcat(A.encoded, map(B -> B.encoded, Bs)...))
end

function ==(A::VectorOfEncodedSimilarArrays, B::VectorOfEncodedSimilarArrays)
    if A.codec == B.codec
        A.innersize == B.innersize && A.encoded == B.encoded
    else
        invoke(==, Tuple{AbstractArray,AbstractArray}, A, B)
    end
end


const BroadcastedEncodeVectorOfSimilarArrays{T,M,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    NestedArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(|>),
    <:Tuple{
        AbstractVectorOfSimilarArrays{T,M},
        Union{Tuple{C},Ref{C}}
    }
}

function Base.copy(instance::BroadcastedEncodeVectorOfSimilarArrays{T,M,C}) where {T,M,C}
    data = instance.args[1]
    append!(VectorOfEncodedSimilarArrays{T}(only(instance.args[2]), innersize(data)), data)
end


const BroadcastedDecodeVectorOfSimilarArrays{T,M,C<:AbstractArrayCodec} = Base.Broadcast.Broadcasted{
    NestedArrayStyle{1},
    Tuple{Base.OneTo{Int}},
    typeof(collect),
    <:Tuple{VectorOfEncodedSimilarArrays{T,M,C}}
}

Base.copy(instance::BroadcastedDecodeVectorOfSimilarArrays) = _decoded(instance.args[1])



const _VectorOfEncoded{T,N} = Union{VectorOfEncodedArrays{T,N},VectorOfEncodedSimilarArrays{T,N}}

Base.push!(A::_VectorOfEncoded{T,N}, x::AbstractArray{T,N}) where {T,N} = _push_encoded!(A, Vector{UInt8}(), x)

function Base.append!(A::_VectorOfEncoded{T,N}, xs::AbstractVector{<:AbstractArray{T,N}}) where {T,N}
    buf = Vector{UInt8}()
    for x in xs
        _push_encoded!(A, buf, x)
    end
    A
end
