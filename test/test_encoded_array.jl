# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

using EncodedArrays
using Test

using ArraysOfArrays

# Minimal codec for arrays of any dimensionality, stores the raw bytes:
struct RawArrayCodec <: AbstractArrayCodec end

function EncodedArrays.encode_data!(encoded::AbstractVector{UInt8}, codec::RawArrayCodec, data::AbstractArray)
    bytes = reinterpret(UInt8, vec(Array(data)))
    resize!(encoded, length(bytes))
    copyto!(encoded, bytes)
end

function EncodedArrays.decode_data!(data::AbstractArray{T}, codec::RawArrayCodec, encoded::AbstractVector{UInt8}) where {T}
    vals = reinterpret(T, Vector(encoded))
    length(data) == length(vals) || resize!(data, length(vals))
    copyto!(data, vals)
    data
end

@testset "encoded_array" begin
    data = rand(Int16(-1000):Int16(2000), 21)
    codec = VarlenDiffArrayCodec()

    data_enc = data |> codec

    @testset "ctors and conversions" begin
        @test @inferred(Array(data_enc)) == data
        @test typeof(Array(data_enc)) == Array{eltype(data),1}
        @test @inferred(Array{Int16}(data_enc)) == data
        @test @inferred(Array{Int16,1}(data_enc)) == data
        @test @inferred(Vector(data_enc)) == data
        @test @inferred(Vector{Int16}(data_enc)) == data
        @test typeof(Vector{Int16}(data_enc)) == Vector{Int16}
        @test @inferred(Vector{Int32}(data_enc)) == data
        @test typeof(Vector{Int32}(data_enc)) == Vector{Int32}

        @test @inferred(convert(Array, data_enc)) == data
        @test typeof(convert(Array, data_enc)) == Array{eltype(data),1}
        @test @inferred(convert(Array{Int16}, data_enc)) == data
        @test @inferred(convert(Array{Int16,1}, data_enc)) == data
        @test @inferred(convert(Vector, data_enc)) == data
        @test @inferred(convert(Vector{Int16}, data_enc)) == data
        @test typeof(convert(Vector{Int16}, data_enc)) == Vector{Int16}
        @test @inferred(convert(Vector{Int32}, data_enc)) == data
        @test typeof(convert(Vector{Int32}, data_enc)) == Vector{Int32}

        @test @inferred(EncodedArray{Int16}(codec, length(data), codeunits(data_enc))) == data_enc
        @test EncodedArray{Int16}(codec, (length(data),), codeunits(data_enc)) == data_enc

        data_enc_view = EncodedArray{Int16}(codec, size(data), view(codeunits(data_enc), :))
        @test @inferred(convert(typeof(data_enc), data_enc_view)) isa typeof(data_enc)
        @test convert(typeof(data_enc), data_enc_view) == data_enc

        @test IndexStyle(typeof(data_enc)) == IndexLinear()
    end

    @testset "collect" begin
        @test @inferred(collect(data_enc)) == data
        @test typeof(collect(data_enc)) == typeof(data)
    end

    @testset "getindex" begin
        @test @inferred(data_enc[:]) == data
        @test typeof(data_enc[:]) == Array{eltype(data),1}

        @test @inferred(data_enc[:]) == data
        @test @inferred(data_enc[1:21]) == data
        @test @inferred(data_enc[5:15]) == data[5:15]
        @test @inferred(data_enc[7]) == data[7]
    end

    @testset "setindex!" begin
        tmp = zero.(data)
        @test (tmp[:] = data_enc) == data

        tmp = vcat(zero.(data), zero.(data))
        tmp2 = copy(tmp)
        tmp[10:30] = data_enc
        tmp2[10:30] = data
        @test tmp == tmp2
    end

    @testset "equality" begin
        @test @inferred data == data_enc
        @test @inferred data_enc == data
        @test @inferred data_enc == data_enc

        # Different codec or size compares by decoded content:
        @test data_enc == (data |> RawArrayCodec())
        @test data_enc != (data[1:5] |> codec)
    end

    @testset "append!" begin
        A = similar(data, 0)
        @test @inferred(append!(A, data_enc)) === A
        @test A == data

        A = data[1:4]
        @test @inferred(append!(A, data_enc)) === A
        @test A == vcat(data[1:4], data)
    end

    @testset "append!" begin
        A = similar(data)
        @test @inferred(copyto!(A, data_enc)) === A
        @test A == data

        @test_throws BoundsError @inferred(copyto!(similar(data, 5), data_enc))
    end

    @testset "multi-dimensional arrays" begin
        codec = RawArrayCodec()
        A = rand(Int32, 3, 4)
        A_enc = A |> codec
        @test A_enc isa EncodedArray{Int32,2}
        @test size(A_enc) == size(A)
        @test @inferred(Matrix(A_enc)) == A
        @test @inferred(convert(Matrix, A_enc)) == A
        @test @inferred(Array{Int32,2}(A_enc)) == A
        @test A_enc == A
        @test A == A_enc
    end

    @testset "VectorOfEncodedArrays" begin
        codec = VarlenDiffArrayCodec()
        data_orig = VectorOfArrays([cumsum(rand(-5:5, rand(1:100))) for i in 1:10])
        data_enc = @inferred(broadcast(|>, data_orig, codec))
        @test data_enc isa VectorOfEncodedArrays
        @test (a -> collect(a)).(data_enc) == data_orig
        data_dec = @inferred(broadcast(collect, data_enc) )
        @test data_dec isa VectorOfArrays
        @test data_dec == data_orig
        @test @inferred(data_enc[2]) isa EncodedArray
        @test @inferred(collect(data_enc[2])) == data_orig[2]
        @test @inferred(data_enc[2:5]) isa VectorOfEncodedArrays
        @test @inferred(broadcast(collect, data_enc[2:5])) == data_orig[2:5]
        @test @inferred(innersizes(data_enc)) == size.(data_orig)
        @test IndexStyle(typeof(data_enc)) == IndexLinear()

        mat_orig = VectorOfArrays([rand(Int32, rand(1:3), rand(1:3)) for i in 1:5])
        mat_enc = @inferred(broadcast(|>, mat_orig, RawArrayCodec()))
        @test mat_enc isa VectorOfEncodedArrays
        mat_dec = @inferred(broadcast(collect, mat_enc))
        @test mat_dec isa VectorOfArrays{Int32,2}
        @test mat_dec == mat_orig
    end

    @testset "VectorOfEncodedSimilarArrays" begin
        codec = VarlenDiffArrayCodec()
        data_orig = VectorOfSimilarArrays(cumsum(rand(-5:5, 100, 10), dims = 1))
        data_enc = @inferred(broadcast(|>, data_orig, codec))
        @test data_enc isa VectorOfEncodedSimilarArrays
        @test (a -> collect(a)).(data_enc) == data_orig
        data_dec = @inferred(broadcast(collect, data_enc) )
        @test data_dec isa VectorOfSimilarArrays{Int,1}
        @test data_dec == data_orig
        @test @inferred(data_enc[2]) isa EncodedArray
        @test @inferred(collect(data_enc[2])) == data_orig[2]
        @test @inferred(data_enc[2:5]) isa VectorOfEncodedSimilarArrays
        @test @inferred(broadcast(collect, data_enc[2:5])) == data_orig[2:5]

        @test data_enc isa AbstractVectorOfSimilarArrays{Int,1}
        @test @inferred(innersize(data_enc)) == (100,)
        @test IndexStyle(typeof(data_enc)) == IndexLinear()
        @test fused(data_enc) == fused(data_orig)
        @test parent(data_enc) == parent(data_orig)
        @test data_enc == data_orig
        @test stack(data_enc) == stack(data_orig)
    end
end # testset
