var documenterSearchIndex = {"docs":
[{"location":"api/#API-1","page":"API","title":"API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"DocTestSetup  = quote\n    using EncodedArrays\nend","category":"page"},{"location":"api/#Types-1","page":"API","title":"Types","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Order = [:type]","category":"page"},{"location":"api/#Functions-1","page":"API","title":"Functions","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Order = [:function]","category":"page"},{"location":"api/#Documentation-1","page":"API","title":"Documentation","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Modules = [EncodedArrays]\nOrder = [:type, :function]","category":"page"},{"location":"api/#EncodedArrays.AbstractArrayCodec","page":"API","title":"EncodedArrays.AbstractArrayCodec","text":"abstract type AbstractArrayCodec <: Codecs.Codec end\n\nAbstract type for arrays codecs.\n\nSubtypes must implement the AbstractEncodedArray API. Most coded should use EncodedArray as the concrete subtype of AbstractArrayCodec. Codecs that use a custom subtype of AbstractEncodedArray must implement\n\nEncodedArrays.encarraytype(::Type{<:AbstractArrayCodec},::Type{<:AbstractArray{T,N}})::Type{<:AbstractEncodedArray{T,N}}\n\n\n\n\n\n","category":"type"},{"location":"api/#EncodedArrays.AbstractEncodedArray","page":"API","title":"EncodedArrays.AbstractEncodedArray","text":"AbstractEncodedArray{T,N} <: AbstractArray{T,N}\n\nAbstract type for arrays that store their elements in encoded/compressed form.\n\nIn addition to the standard AbstractArray API, an AbstractEncodedArray must support the functions\n\nEncodedArrays.getcodec(A::EncodedArray): Returns the codec.\nBase.codeunits(A::EncodedArray): Returns the internal encoded data representation.\n\nEncoded arrays will typically be created via\n\nA_enc = (codec::AbstractArrayCodec)(A::AbstractArray)\n\nor\n\nA_enc = AbstractEncodedArray(undef, codec::AbstractArrayCodec)\nappend!(A_enc, B::AbstractArray)\n\nDecoding happens via standard array conversion or assignment:\n\nA_dec = Array(A)\nA_dec = convert(Array,A)\nA_dec = A[:]\n\nA_dec = Array{T,N}(undef, size(A_enc)...)\nA_dec[:] = A_enc\n\n\n\n\n\n","category":"type"},{"location":"api/#EncodedArrays.EncodedArray","page":"API","title":"EncodedArrays.EncodedArray","text":"EncodedArray{T,N,C,DV} <: AbstractEncodedArray{T,N}\n\nConcrete type for AbstractEncodedArrays.\n\nConstructor:\n\nEncodedArray{T}(\n    codec::AbstractArrayCodec,\n    size::NTuple{N,Integer},\n    encoded::AbstractVector{UInt8}\n)\n\nCodecs using EncodedArray only need to implement EncodedArrays.encode_data! and EncodedArrays.decode_data!.\n\nIf length of the decoded data can be inferred from the encoded data, a constructor\n\nEncodedArray{T,N}(codec::MyCodec,encoded::AbstractVector{UInt8})\n\nshould also be defined. By default, two EncodedArrays that have the same codec and size are assumed to be equal if and only if their code units are equal.\n\nGeneric methods for the rest of the AbstractEncodedArray API are already provided for EncodedArray. \n\n\n\n\n\n","category":"type"},{"location":"api/#EncodedArrays.VarlenDiffArrayCodec","page":"API","title":"EncodedArrays.VarlenDiffArrayCodec","text":"VarlenDiffArrayCodec <: AbstractArrayCodec\n\n\n\n\n\n","category":"type"},{"location":"api/#EncodedArrays.VectorOfEncodedArrays","page":"API","title":"EncodedArrays.VectorOfEncodedArrays","text":"const VectorOfEncodedArrays{T,N,...} = StructArray{EncodedArray{...},...}\n\nAlias for vectors of encoded arrays that store the code units of all elements in contiguous fashion using StructArrays.StructArray and ArraysOfArray.VectorOfArrays.\n\n\n\n\n\n","category":"type"},{"location":"api/#Base.:|>-Union{Tuple{T}, Tuple{AbstractArray{T,N} where N,AbstractArrayCodec}} where T","page":"API","title":"Base.:|>","text":"¦>(A::AbstractArray{T}, codec::AbstractArrayCodec)::AbstractEncodedArray\n\nEncode A using codec and return an AbstractEncodedArray. The default implementation returns an EncodedArray.\n\n\n\n\n\n","category":"method"},{"location":"api/#EncodedArrays.decode_data!","page":"API","title":"EncodedArrays.decode_data!","text":"decode_data!(data::AbstractArray, codec::AbstractArrayCodec, encoded::AbstractVector{UInt8})\n\nDepending on codec, may or may not resize decoded to fit the size of the decoded data. Codecs may require decoded to be of correct size (e.g. to improved performance or when the size/shape of the decoded data cannot be easily inferred from the encoded data.\n\nReturns data.\n\n\n\n\n\n","category":"function"},{"location":"api/#EncodedArrays.encode_data!","page":"API","title":"EncodedArrays.encode_data!","text":"encode_data!(encoded::AbstractVector{UInt8}, codec::AbstractArrayCodec, data::AbstractArray)\n\nWill resize encoded as necessary to fit the encoded data.\n\nReturns encoded.\n\n\n\n\n\n","category":"function"},{"location":"api/#EncodedArrays.getcodec","page":"API","title":"EncodedArrays.getcodec","text":"EncodedArrays.getcodec(A::AbstractEncodedArray)::AbstractArrayCodec\n\nReturns the codec used to encode/compress A.\n\n\n\n\n\n","category":"function"},{"location":"api/#EncodedArrays.read_autozz_varlen","page":"API","title":"EncodedArrays.read_autozz_varlen","text":"read_autozz_varlen(io::IO, ::Type{<:Integer})\n\nRead an integer of type T from io, using zig-zag decoding depending on whether T is signed or unsigned.\n\n\n\n\n\n","category":"function"},{"location":"api/#EncodedArrays.read_varlen-Tuple{IO,Type{#s14} where #s14<:Unsigned}","page":"API","title":"EncodedArrays.read_varlen","text":"read_varlen(io::IO, T::Type{<:Unsigned})\n\nRead an unsigned variable-length integer value of type T from io. If the next value encoded in x is too large to be represented by T, an exception is thrown.\n\nSee EncodedArrays.write_varlen.\n\n\n\n\n\n","category":"method"},{"location":"api/#EncodedArrays.write_varlen-Tuple{IO,Unsigned}","page":"API","title":"EncodedArrays.write_varlen","text":"write_varlen(io::IO, x::Unsigned)\n\nWrite unsigned integer value x to IO using variable-length coding. Data is written in LSB fashion in units of one byte. The highest bit of each byte indicates if more bytes will need to be read, the 7 lower bits contain the next 7 bits of x. \n\n\n\n\n\n","category":"method"},{"location":"LICENSE/#LICENSE-1","page":"LICENSE","title":"LICENSE","text":"","category":"section"},{"location":"LICENSE/#","page":"LICENSE","title":"LICENSE","text":"using Markdown\nMarkdown.parse_file(joinpath(@__DIR__, \"..\", \"..\", \"LICENSE.md\"))","category":"page"},{"location":"#EncodedArrays.jl-1","page":"Home","title":"EncodedArrays.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"EncodedArray provides an API for arrays that store their elements in encoded/compressed form. This package is meant to be lightweight and only implements a simple codec VarlenDiffArrayCodec. As codec implementations are often complex and have various dependencies, more advanced codecs should be implemented in separate packages.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Random access on an encoded array will typically be very inefficient, but linear access may be efficient (depending on the codec). Accessing the whole array contents at once, e.g. via collect(A), A[:], or copying/appending/conversion to a regular array, must be efficient.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"An encoded array will typically have very inefficient random access, but may have efficient linear access and must be efficient when accessing the whole array contents at once via getindex, copying/appending to a regular array, etc.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"This package defines two central abstract types, AbstractEncodedArray and AbstractArrayCodec. It also defines a concrete type EncodedArray that implements most of the API and only leaves EncodedArrays.encode_data! and EncodedArrays.decode_data! for a new codec to implement.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Custom broadcasting optimizations are not implemented yet but will likely be added in the future.","category":"page"}]
}
