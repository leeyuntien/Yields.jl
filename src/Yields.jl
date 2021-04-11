module Yields

import Interpolations

# don't export type, as the API of Yields.Zero is nicer and 
# less polluting than Zero and less/equally verbose as ZeroYieldCurve or ZeroCruve
export rate, discount, accumulation,forward, Yield, Rate, Continuous, Periodic, rate
# USTreasury,  AbstractYield
# Zero,Constant, Forward

abstract type CompoundingFrequency end
Base.Broadcast.broadcastable(x::T) where{T<:CompoundingFrequency} = Ref(x) 

struct Continuous <: CompoundingFrequency end

Continuous(x) = Rate(x,Continuous())

struct Periodic <: CompoundingFrequency
    frequency::Int
end
Periodic(freq,x) = Rate(Periodic(freq),x)

struct Rate
    value
    compounding::CompoundingFrequency
end

# Base.:==(r1::Rate,r2::Rate) = (r1.value == r2.value) && (r1.compounding == r2.compounding)

"""
    Rate(x,freq=1)
    Rate(CompoundingFrequency,x)

Rate is a type that indicates the compounding frequency of the rate `x`.

Periodic rates can be constructed via `Rate(x,m)` or `Rate(Periodic(m),x)` where `m` is the periodic frequency.

Continuous rates can be constructed via `Rate(x, Inf)` or `Rate(Continuous(), x)`.
"""
Rate(x) = Rate(Periodic(1),x)
Rate(x,freq::T) where {T<:Real} = isinf(freq) ? Rate(x,Continuous()) : Rate(x,Periodic(freq))


"""
    covert(T::CompoundingFrequency,r::Rate)

Returns a `Rate` with an equivalent discount but represented with a different compounding frequency.
"""
Base.convert(r::Rate,T::CompoundingFrequency) = convert(r,r.compounding,T)
function Base.convert(r,from::Continuous,to::Continuous)
    return r
end

function Base.convert(r,from::Continuous,to::Periodic)
    return Rate(to.frequency * (exp(r.value/to.frequency) - 1),to)
end

function Base.convert(r,from::Periodic,to::Continuous)
    return Rate(from.frequency * log(1 + r.value / from.frequency),to)
end

function Base.convert(r,from::Periodic,to::Periodic)
    c = convert(r,from,Continuous())
    return convert(c,Continuous(),to)
end

rate(r::Rate) = r.value



"""
An AbstractYield is an object which can be called with:

- `rate(yield,time)` for the spot rate at a given time
- `discount(yield,time)` for the spot discount rate at a given time

"""
abstract type AbstractYield end

# make interest curve broadcastable so that you can broadcast over multiple`time`s in `interest_rate`
Base.Broadcast.broadcastable(ic::T) where {T<:AbstractYield} = Ref(ic) 

struct YieldCurve <: AbstractYield
    rates
    maturities
    discount # discount function for time
end

# Wrapping a a scalar value in this type allows for dispatch to operate as intended 
# (otherwise `Base.accumulate(<:Real,<:Real) tries to do something other than accumulate interest)
"""
    Constant(rate)

Construct a yield object where the spot rate is constant for all maturities.

# Examples

```julia-repl
julia> y = Yields.Constant(0.05)
julia> discount(y,2)
0.9070294784580498     # 1 / (1.05) ^ 2
```
"""
struct Constant <: AbstractYield
    rate
end

function Constant(rate::T) where {T <: Real}
    return Constant(Rate(rate,Periodic(1)))
end

rate(c::Constant) = c.rate
rate(c::Constant,time) = c.rate
discount(c::T,time) where {T <: Real} = discount(Constant(c),time)
discount(r::Constant,time) = 1 / accumulation(r,time)

accumulation(r::Constant,time) = accumulation(r.rate.compounding,r,time)
accumulation(::Continuous,r::Constant,time) = exp(rate(r.rate) * time)
accumulation(::Periodic,r::Constant,time) = (1 + rate(r.rate) / r.rate.compounding.frequency) ^ (r.rate.compounding.frequency * time)

"""
    Step(rates,times)

Create a yield curve object where the applicable rate is the effective rate of interest applicable until corresponding time.

# Examples

```julia-repl
julia>y = Yields.Step([0.02,0.05], [1,2])

julia>rate(y,0.5)
0.02

julia>rate(y,1.5)
0.05

julia>rate(y,2.5)
0.05
```
"""
struct Step <: AbstractYield
    rates
    times
end

Step(rates) = Step(rates, collect(1:length(rates)))

function rate(y::Step, time)
    i = findfirst(t -> time <= t, y.times)
    if isnothing(i)
        return y.rates[end]
    else
        return y.rates[i]
    end
end

function discount(y::Step, time)
    v = 1 / (1 + y.rates[1])^min(y.times[1], time)

    if y.times[1] >= time
        return v
    end

    for i in 2:length(y.times)

        if y.times[i] >= time
            # take partial discount and break
            v /= (1 + y.rates[i])^(time - y.times[i - 1])
            break
        else
            # take full discount and continue
            v /=  (1 + y.rates[i])^(y.times[i] - y.times[i - 1])
        end

    end

    return v
end

function Zero(rates, maturities)
    # bump to a constant yield if only given one rate
    length(rates) == 1 && return Constant(rate[1])

    return YieldCurve(
        rates,
        maturities,
        linear_interp(maturities,rates)
    )
end


function Zero(rates)
    # bump to a constant yield if only given one rate
    maturities = collect(1:length(rates))
    return Zero(rates, maturities)
end

"""
Construct a curve given a set of bond yields priced at par with a single coupon per period.
"""
function Par(rate, maturity;)
    # bump to a constant yield if only given one rate
    if length(rate) == 1
        return Constant(rate[1])
    end

    spot = similar(rate) 

    spot[1] = rate[1]

    for i in 2:length(rate)
        coupon_pv = sum(rate[i] / (1 + spot[j])^maturity[j] for j in 1:i - 1) # not including the one paid at maturity

        spot[i] = ((1 + rate[i]) / (1 - coupon_pv))^(1 / maturity[i]) - 1
    end



    return YieldCurve(
        rate,
        maturity,
        linear_interp(maturity,spot)
        )
end

"""
    Forward(rate_vector)

Takes a vector of 1-period forward rates and constructs a discount curve.
"""
function Forward(rate_vector)
    zeros = similar(rate_vector)
    zeros[1] = rate_vector[1]
    for i in 2:length(rate_vector)
        zeros[i] = (prod(1 .+ rate_vector[1:i]))^(1 / i) - 1
    end
    return Zero(zeros, 1:length(rate_vector))
end

function Forward(rate_vector, times)
    disc_v = similar(rate_vector)
    disc_v[1] = 1 / (1 + rate_vector[1])^times[1]
    for i in 2:length(rate_vector)
        ∇t = times[i] - times[i - 1]
        disc_v[i] = disc_v[i - 1] / (1 + rate_vector[i])^∇t
    end

    return Zero(1 ./ disc_v.^(1 ./ times) .- 1, times)
end

"""
    USTreasury(rates,maturities)

Takes CMT yields (bond equivalent), and assumes that instruments <= one year maturity pay no coupons and that the rest pay semi-annual.
"""
function USTreasury(rates, maturities)
    z = zeros(length(rates))

    # use the discount rate for T-Bills with maturities <= 1 year
    for (i, (rate, mat)) in enumerate(zip(rates, maturities))
        
        if mat <= 1 
            z[i] = (1 + rate * mat) ^ (1/mat) -1
        else
            # uses interpolation b/c of common, but uneven maturities often present under 1 year.
            curve = linear_interp(maturities, z)
            pmts = [rate / 2 for t in 0.5:0.5:mat] # coupons only
            pmts[end] += 1 # plus principal

            discount =  1 ./ (1 .+ curve.(0.5:0.5:(mat - .5)))
            z[i] = ((1 - sum(discount .* pmts[1:end - 1])) / pmts[end])^- (1 / mat) - 1

        end




        
    end

    return YieldCurve(rates, maturities, linear_interp(maturities, z))


    return YieldCurve(
        rate,
        maturity,
        linear_interp(maturity,rate)
        )
end

function ParYieldCurve(rates, maturities)

end


## Generic and Fallbacks
"""
    rate(yield,time)

The annual effective spot rate at `time` for the given `yield`.
"""
rate(yc,time) = yc.spline(time)

"""
    discount(yield,time)

The discount factor for the `yield` from time zero through `time`. If yield is a `Real` number, will assume a `Constant` interest rate.
"""
discount(yc,time) = 1 / (1 + rate(yc, time))^time

"""
    discount(yield,from,to)

The discount factor for the `yield` from time `from` through `to`.
"""
discount(yc,from,to) = discount(yc, to) / discount(yc, from)

function forward(yc, from, to)
    return (accumulate(yc, to) / accumulate(yc, from))^(1 / (to - from)) - 1
end
function forward(yc, to)
    from = to - 1 
    return forward(yc, from, to)
end

"""
    accumulate(yield,time)

The accumulation factor for the `yield` from time zero through `time`.
"""
function Base.accumulate(y::T, time) where {T <: AbstractYield}
    return 1 / discount(y, time)
end

function Base.accumulate(y::T,from,to) where {T <: AbstractYield}
    return 1 / discount(y,from,to)
end

## Curve Manipulations
struct RateCombination <: AbstractYield
    r1
    r2
    op
end

rate(rc::RateCombination,time) = rc.op(rate(rc.r1, time), rate(rc.r2, time))
function discount(rc::RateCombination, time) 
    a1 = discount(rc.r1,time)^(-1/time) - 1  
    a2 = discount(rc.r2,time)^(-1/time) - 1
    return 1 / (1 + rc.op(a1,a2)) ^ time
end

"""
    Yields.AbstractYield + Yields.AbstractYield

The addition of two yields will create a `RateCombination`. For `rate`, `discount`, and `accumulation` purposes the spot rates of the two curves will be added together.
"""
function Base.:+(a::AbstractYield, b::AbstractYield)
    return RateCombination(a, b, +) 
end

function Base.:+(a::Constant, b::Constant)
    a_kind = rate(a).compounding
    rate_new_basis = rate(convert(rate(b),a_kind))
    return Constant(
        Rate(
            rate(a.rate) + rate_new_basis,
            a_kind
            )
        )
end

function Base.:+(a::T, b) where {T<:AbstractYield}
    return a + Yield(b)
end

function Base.:+(a, b::T) where {T<:AbstractYield}
    return Yield(a) + b
end

# TODO Notes
# - Combinations of like CompoundingFrequency should be addable, or convert if different, which is correct and safer
# - Using Rate as foundation for other curves should make boostrapping more straightforward and support mixed periods in curve (e.g. treasury)


"""
    Yields.AbstractYield - Yields.AbstractYield

The subtraction of two yields will create a `RateCombination`. For `rate`, `discount`, and `accumulation` purposes the spot rates of the second curves will be subtracted from the first.
"""
function Base.:-(a::AbstractYield, b::AbstractYield)
    return RateCombination(a, b, -) 
end

function Base.:+(a::Constant, b::Constant)
    a_kind = rate(a).compounding
    rate_new_basis = rate(convert(rate(b),a_kind))
    return Constant(
        Rate(
            rate(a.rate) - rate_new_basis,
            a_kind
            )
        )
end

function Base.:-(a::T, b) where {T<:AbstractYield}
    return a - Yield(b)
end

function Base.:-(a, b::T) where {T<:AbstractYield}
    return Yield(a) - b
end

""" 
    yield(rate)
    yield(forwards)

Yields provides a default, convienience construction for an AbstractYield.

"""

function Yield(i::T) where {T<:Real}
    return Constant(i)
end

function Yield(i::Vector{T}) where {T<:Real}
    return Forward(i)
end

linear_interp(xs,ys) = Interpolations.extrapolate(
    Interpolations.interpolate((xs,), ys, Interpolations.Gridded(Interpolations.Linear())), 
    Interpolations.Flat()
    ) 
end
