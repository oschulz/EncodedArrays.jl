# EncodedArrays.jl

[![Documentation for stable version](https://img.shields.io/badge/docs-stable-blue.svg)](https://oschulz.github.io/EncodedArrays.jl/stable)
[![Documentation for development version](https://img.shields.io/badge/docs-dev-blue.svg)](https://oschulz.github.io/EncodedArrays.jl/dev)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://github.com/oschulz/EncodedArrays.jl/workflows/CI/badge.svg?branch=main)](https://github.com/oschulz/EncodedArrays.jl/actions?query=workflow%3ACI)
[![Codecov](https://codecov.io/gh/oschulz/EncodedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/oschulz/EncodedArrays.jl)

EncodedArray provides an API for arrays that store their elements in
encoded/compressed form. This package is meant to be lightweight and only
implements a simple codec `VarlenDiffArrayCodec`. As codec implementations are
often complex and have various dependencies, more advanced codecs should
be implemented in separate packages.


## Documentation

* [Documentation for stable version](https://oschulz.github.io/EncodedArrays.jl/stable)
* [Documentation for development version](https://oschulz.github.io/EncodedArrays.jl/dev)
