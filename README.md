# EncodedArrays.jl

[![Documentation for stable version](https://img.shields.io/badge/docs-stable-blue.svg)](https://oschulz.github.io/EncodedArrays.jl/stable)
[![Documentation for development version](https://img.shields.io/badge/docs-dev-blue.svg)](https://oschulz.github.io/EncodedArrays.jl/dev)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Travis Build Status](https://travis-ci.com/oschulz/EncodedArrays.jl.svg?branch=master)](https://travis-ci.com/oschulz/EncodedArrays.jl)
[![Codecov](https://codecov.io/gh/oschulz/EncodedArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/oschulz/EncodedArrays.jl)

EncodedArray provides an API for arrays that store their elements in
encoded/compressed form. This package is meant to be lightweight and only
implements a simple codec `VarlenDiffArrayCodec`. As codec implementations are
often complex and have various dependencies, more advanced codecs should
be implemented in separate packages.


## Documentation

* [Documentation for stable version](https://oschulz.github.io/EncodedArrays.jl/stable)
* [Documentation for development version](https://oschulz.github.io/EncodedArrays.jl/dev)
