## utility functions mainly used by the private math functions in priv.jl

function is_fma_fast end
for T in (Float32, Float64)
    @eval is_fma_fast(::Type{$T}) = $(muladd(nextfloat(one(T)),nextfloat(one(T)),-nextfloat(one(T),2)) != zero(T))
end
is_fma_fast() = is_fma_fast(Float64) && is_fma_fast(Float32)


@inline exponent_max{T<:FloatTypes}(::Type{T}) = Int(exponent_mask(T) >> significand_bits(T))

# _sign emits better native code than sign but does not properly handle the Inf/NaN cases
@inline _sign{T<:FloatTypes}(d::T) =  flipsign(T(1), d)

@inline rint{T<:FloatTypes}(x::T) = unsafe_trunc(Int, ifelse(x < 0, x - T(0.5), x + T(0.5)))

@inline integer2float(::Type{Float64}, m::Int) = reinterpret(Float64, (m % Int64) << significand_bits(Float64))
@inline integer2float(::Type{Float32}, m::Int) = reinterpret(Float32, (m % Int32) << significand_bits(Float32))

@inline float2integer(d::Float64) = (reinterpret(Int64, d) >> significand_bits(Float64)) % Int
@inline float2integer(d::Float32) = (reinterpret(Int32, d) >> significand_bits(Float32)) % Int

@inline pow2i{T<:FloatTypes}(::Type{T}, q::Int) = integer2float(T, q + exponent_bias(T))

# sqrt without the domain checks which we don't need since we handle the checks ourselves
_sqrt{T<:FloatTypes}(x::T) = Base.box(T, Base.sqrt_llvm_fast(Base.unbox(T,x)))

@inline ispinf{T<:FloatTypes}(x::T) = x == T(Inf)
@inline isninf{T<:FloatTypes}(x::T) = x == T(-Inf)

macro horner_split(x,p...)
    t1 = gensym("x1")
    t2 = gensym("x2")
    blk = quote
        $t1 = $(esc(x))
        $t2 = $(esc(x)) * $(esc(x))
    end
    n = length(p)
    p0 = esc(p[1])
    if isodd(n)
        ex_o = esc(p[end-1])
        ex_e = esc(p[end])
        for i = n-3:-2:2
            ex_o = :(muladd($(t2), $ex_o, $(esc(p[i]))))
        end
        for i = n-2:-2:2
            ex_e = :(muladd($(t2), $ex_e, $(esc(p[i]))))
        end
    elseif iseven(n)
        ex_o = esc(p[end])
        ex_e = esc(p[end-1])
        for i = n-2:-2:2
            ex_o = :(muladd($(t2), $ex_o, $(esc(p[i]))))
        end
        for i = n-3:-2:2
            ex_e = :(muladd($(t2), $ex_e, $(esc(p[i]))))
        end
    end
    push!(blk.args,:($(p0) + $(t1)*$(ex_o) + $(t2)*$(ex_e)) )    
    return blk
end
