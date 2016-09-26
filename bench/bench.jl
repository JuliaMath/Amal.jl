using Libm
using BenchmarkTools
using JLD, DataStructures

RETUNE  = false
VERBOSE = true
DETAILS = false

test_types = (Float64, Float32) # Which types do you want to bench?

const bench = ("Base","Sleef")
const suite = BenchmarkGroup()
for n in bench
    suite[n] = BenchmarkGroup([n])
end


bench_reduce(f::Function, X) = mapreduce(x -> reinterpret(Unsigned,x), |, f(x) for x in X)
typealias FloatTypes Union{Float32,Float64}
MRANGE(::Type{Float64}) = 10000000
MRANGE(::Type{Float32}) = 10000
IntF(::Type{Float64}) = Int64
IntF(::Type{Float32}) = Int32
x_trig{T<:FloatTypes}(::Type{T}) = begin
    x_trig = T[]
    for i = 1:10000
        s = reinterpret(T, reinterpret(IntF(T), T(pi)/4 * i) - IntF(T)(20))
        e = reinterpret(T, reinterpret(IntF(T), T(pi)/4 * i) + IntF(T)(20))
        d = s
        while d <= e 
            append!(x_trig, d)
            d = reinterpret(T, reinterpret(IntF(T), d) + IntF(T)(1))
        end
    end
    x_trig = append!(x_trig, -10:0.0002:10)
    x_trig = append!(x_trig, -MRANGE(T):200.1:MRANGE(T))
end
x_exp{T<:FloatTypes}(::Type{T})        = map(T, vcat(-10:0.0002:10, -1000:0.1:1000))
x_exp2{T<:FloatTypes}(::Type{T})       = map(T, vcat(-10:0.0002:10, -120:0.023:1000, -1000:0.02:2000))
x_exp10{T<:FloatTypes}(::Type{T})      = map(T, vcat(-10:0.0002:10, -35:0.023:1000, -300:0.01:300))
x_expm1{T<:FloatTypes}(::Type{T})      = map(T, vcat(-10:0.0002:10, -1000:0.021:1000, -1000:0.023:1000, 10.0.^-(0:0.02:300), -10.0.^-(0:0.02:300), 10.0.^(0:0.021:300), -10.0.^-(0:0.021:300)))
x_log{T<:FloatTypes}(::Type{T})        = map(T, vcat(0.0001:0.0001:10, 0.001:0.1:10000, 1.1.^(-1000:1000), 2.1.^(-1000:1000)))
x_log10{T<:FloatTypes}(::Type{T})      = map(T, vcat(0.0001:0.0001:10, 0.0001:0.1:10000))
x_log1p{T<:FloatTypes}(::Type{T})      = map(T, vcat(0.0001:0.0001:10, 0.0001:0.1:10000, 10.0.^-(0:0.02:300), -10.0.^-(0:0.02:300)))
x_atrig{T<:FloatTypes}(::Type{T})      = map(T, vcat(-1:0.00002:1))
x_atan{T<:FloatTypes}(::Type{T})       = map(T, vcat(-10:0.0002:10, -10000:0.2:10000, -10000:0.201:10000))
x_cbrt{T<:FloatTypes}(::Type{T})       = map(T, vcat(-10000:0.2:10000, 1.1.^(-1000:1000), 2.1.^(-1000:1000)))
x_trigh{T<:FloatTypes}(::Type{T})      = map(T, vcat(-10:0.0002:10, -1000:0.02:1000))
x_asinhatanh{T<:FloatTypes}(::Type{T}) = map(T, vcat(-10:0.0002:10, -1000:0.02:1000))
x_acosh{T<:FloatTypes}(::Type{T})      = map(T, vcat(1:0.0002:10, 1:0.02:1000))

for f in (:atanh,)
    @eval begin
        ($f)(x::Float64) = ccall(($(string(f)),Base.libm_name), Float64, (Float64,), x)
        ($f)(x::Float32) = ccall(($(string(f,"f")),Base.libm_name), Float32, (Float32,), x)
    end
end

const micros = OrderedDict(
    "sin"   => x_trig,
    "cos"   => x_trig,
    "tan"   => x_trig,
    "exp"   => x_exp,
    "exp2"  => x_exp2,
    "exp10" => x_exp10,
    "expm1" => x_expm1,
    "log"   => x_log,
    "log10" => x_log10,
    "log1p" => x_log1p,
    "asin"   => x_atrig,
    "acos"   => x_atrig,
    "atan"   => x_atan,
    "sinh"  => x_trigh,
    "cosh"  => x_trigh,
    "tanh"  => x_trigh,
    "asinh"  => x_asinhatanh,
    "acosh"  => x_acosh,
    "atanh"  => x_asinhatanh,
    "cbrt"  => x_cbrt
    )

for n in ("Base","Sleef")
    for (f,x) in micros
        suite[n][f] = BenchmarkGroup([f])
        for T in test_types
            n == "Sleef" ? fun = Symbol("x",f) : fun = Symbol(f)
            suite[n][f][string(T)] = @benchmarkable bench_reduce($fun, $(x(T)))
        end
    end
end


tune_params = joinpath(dirname(@__FILE__), "params.jld")
if !isfile(tune_params) || RETUNE
    tune!(suite; verbose=VERBOSE)
    save(tune_params, "suite", params(suite))
    println("Saving tuned parameters.")
else
    println("Loading pretuned parameters.")
    loadparams!(suite, load(tune_params, "suite"), :evals, :samples)
end

println("Warming up...")
warmup(suite,VERBOSE)
println("Running micro benchmarks...")
results = run(suite; verbose=VERBOSE)

for f in keys(micros)
    for T in test_types
        println()
        print_with_color(:magenta, string(f, " ", T, " benchmark\n"))
        print_with_color(:blue, "median ratio Sleef/Base\n")
        println(ratio(median(results["Sleef"][f][string(T)]), median(results["Base"][f][string(T)])))
        println()
        if DETAILS
            print_with_color(:blue, "details Sleef/Base\n")
            println(results["Sleef"][f][string(T)])
            println(results["Base"][f][string(T)])
            println()
        end
    end
end
