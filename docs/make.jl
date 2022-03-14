# Use
#
#     DOCUMENTER_DEBUG=true julia --color=yes make.jl local [nonstrict] [fixdoctests]
#
# for local builds.

using Documenter
using EncodedArrays

# Doctest setup
DocMeta.setdocmeta!(
    EncodedArrays,
    :DocTestSetup,
    :(using EncodedArrays);
    recursive=true,
)

makedocs(
    sitename = "EncodedArrays",
    modules = [EncodedArrays],
    format = Documenter.HTML(
        prettyurls = !("local" in ARGS),
        canonical = "https://oschulz.github.io/EncodedArrays.jl/stable/"
    ),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
        "LICENSE" => "LICENSE.md",
    ],
    doctest = ("fixdoctests" in ARGS) ? :fix : true,
    linkcheck = !("nonstrict" in ARGS),
    strict = !("nonstrict" in ARGS),
)

deploydocs(
    repo = "github.com/oschulz/EncodedArrays.jl.git",
    forcepush = true,
    push_preview = true,
)
