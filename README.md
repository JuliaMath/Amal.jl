<div align="center"><img src="https://cloud.githubusercontent.com/assets/4319522/19198797/ee730dec-8c8e-11e6-91f4-0720c391969e.jpg" alt="Amal"></img> </div>


Amal, a pure Julia math library *(a work in progress)*

With full support for `Float16`, `Float32`, and `Float64` types. In the future we plan support for `Float80` and `Float128` types (when they become available in Julia).



The exported functions presently include
```julia
exp, exp2, tan, atan
```
More function to come in the near future. 


[![Travis Build Status](https://travis-ci.org/JuliaMath/Amal.jl.svg?branch=master)](https://travis-ci.org/JuliaMath/Amal.jl)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/307l6b799amrpvks/branch/master?svg=true)](https://ci.appveyor.com/project/musm/Amal-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/JuliaMath/Amal.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaMath/Amal.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaMath/Amal.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaMath/Amal.jl?branch=master)


The Amal library principles include: avoid expensive branches and to avoid table look ups, and to prefer polynomial approximations over rational approximations if accuracy constrains can be  met.  To achieve these goals Amal borrows ideas from several open source math libraries, including SLEEF, Cephes, and Musl. As this library develops these guiding principles may adapt to meet different critera and needs that the Julia community cares for.



## Installation

We recommend running julia with `-O3` for maximal performance using `Amal.jl` and to also build a custom system image by running
```julia
julia> is_windows() && (Pkg.add("WinRPM"); using WinRPM; WinRPM.install("gcc"))
julia> include(joinpath(dirname(JULIA_HOME),"share","julia","build_sysimg.jl"))
julia> build_sysimg(force=true)
```
and then to restart `julia`; this will ensure you are taking full advantage of hardware [FMA](https://en.wikipedia.org/wiki/FMA_instruction_set)  if your CPU supports it.

## Usage

To use  `Amal.jl`
```julia
julia> Pkg.clone("https://github.com/JuliaMath/Amal.jl.git")

julia> using Amal

julia> Amal.exp(2.0)
7.38905609893065

```
