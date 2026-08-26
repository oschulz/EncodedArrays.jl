# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

module EncodedArrays

using ArraysOfArrays
using ArraysOfArrays: NestedArrayStyle
using BitOperations

include("encoded_array.jl")
include("varlen_io.jl")
include("varlen_diff_codec.jl")

end # module
