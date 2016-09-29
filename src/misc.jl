

"""
  pow(x, y)

Exponentiation operator, returns `x` raised to the power `y`.
"""
function pow{T<:Float}(x::T, y::T)
    yi = unsafe_trunc(Int,y)
    yint = yi == y
    yodd = isodd(yi) && yint
    z = expk(dmul(logk(abs(x)), y))
    z = isnan(z) ? T(Inf) : z
    z *= (x >= 0 ? 1 : (!yint ? T(NaN) : (yodd ? -1 : 1)));
    efx = flipsign(abs(x) - 1, y)
    isinf(y) && (z = efx < 0 ? T(0) : (efx == 0 ? T(1) : T(Inf)))
    if isinf(x) || x == 0
        z = (yodd ? _sign(x) : T(1)) * ((x == 0 ? -y : y) < 0 ? T(0) : T(Inf))
    end
    (isnan(x) || isnan(y)) && (z = T(NaN))
    (y == 0 || x == 1) && (z = T(1))
    return z
end


let
global cbrt_fast
global cbrt

const c6d = -0.640245898480692909870982
const c5d = 2.96155103020039511818595
const c4d = -5.73353060922947843636166
const c3d = 6.03990368989458747961407
const c2d = -3.85841935510444988821632
const c1d = 2.2307275302496609725722

const c6f = -0.601564466953277587890625f0
const c5f =  2.8208892345428466796875f0
const c4f = -5.532182216644287109375f0
const c3f =  5.898262500762939453125f0
const c2f = -3.8095417022705078125f0
const c1f =  2.2241256237030029296875f0

global @inline _cbrt(x::Float64) = @horner x c1d c2d c3d c4d c5d c6d
global @inline _cbrt(x::Float32) = @horner x c1f c2f c3f c4f c5f c6f

"""
    cbrt_fast(x)

Return `x^{1/3}`.
"""
function cbrt_fast{T<:Float}(d::T)
    e  = ilog2k(d)
    d  = ldexpk(d,-e)
    r  = (e + 6144) % 3
    q  = r == 1 ? T(M2P13) : T(1)
    q  = r == 2 ? T(M2P23) : q
    q  = ldexpk(q, (e + 6144) ÷ 3 - 2048)
    q  = flipsign(q,d)
    d  = abs(d)
    x  =_cbrt(d)
    y  = x*x
    y  = y*y
    x -= (d*y - x)*T(1/3)
    y  = d*x*x
    y  = (y - T(2/3)*y*(y*x - 1))*q
end


"""
    cbrt(x)

Return `x^{1/3}`. The prefix operator `∛` is equivalent to `cbrt`.
"""
function cbrt{T<:Float}(d::T)
    e  = ilog2k(d)
    d  = ldexpk(d,-e)
    r  = (e + 6144) % 3
    q2 = r == 1 ? MD2P13(T) : Double(T(1))
    q2 = r == 2 ? MD2P23(T) : q2
    q2 = flipsign(q2,d)
    d  = abs(d)
    x  =_cbrt(d)
    y  = x*x
    y  = y*y
    x -= (d*y - x)*T(1/3)
    z  = x
    u  = dsqu(x)
    u  = dsqu(u)
    u  = dmul(u, d)
    u  = dsub(u,x)
    y  = T(u)
    y  = -T(2/3)*y*z
    v  = dadd(dsqu(z), y)
    v  = dmul(v,d)
    v  = dmul(v,q2)
    z  = ldexp(T(v), (e + 6144) ÷ 3 - 2048)
    isinf(d) && (z = flipsign(T(Inf), q2.hi))
    d == 0   && (z = flipsign(T(0), q2.hi))
    return z
end
end


"""
    hypot(x,y)

Compute the hypotenuse `\sqrt{x^2+y^2}` avoiding overflow and underflow.
"""
function hypot{T<:Float}(x::T, y::T)
    x = abs(x)
    y = abs(y)
    if x < y
       x, y = y, x
    end
    r = (x == 0) ? y : y/x
    x*sqrt(T(1) + r*r)
end