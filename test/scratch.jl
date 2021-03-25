using MissingStrategies

function effective_n_cor(x, acf::AbstractVector, ms::MissingStrategy=PassMissing())
    ms === PassMissing() && Missing <: eltype(x) && any(ismissing.(x)) && return(missing)
    n = length(x)
    k = Base.OneTo(min(n,length(acf))-1) # acf starts with lag 0
    if ms === ExactMissing() && (Missing <: eltype(x))
        # count the number of pairs with missings for each lag
        mk = count_forlags((x_i,x_iplusk)->ismissing(x_i) || ismissing(x_iplusk), x, k)
        nf = n - count(ismissing.(x))
        neff = nf/(1 + 2/nf*sum((n .- k .-mk) .* acf[k.+1]))  
    else
        neff = n/(1 + 2/n*sum((n .- k) .* acf[k.+1]))  
    end
end

autocor(xm, SkipMissing())
autocor(xm, ExactMissing())
autocor(xm, PassMissing())
autocor(allowmissing(x))
autocor(x)
autocor(xm)
StatsBase.autocor(xm) # overwritten


xm = [1,2,missing]
x = [1,2]
using Missings, MissingStrategies, StatsBase
import StatsBase: autocor
#@handlemissings2(autocor)
@handlemissings2(autocor, true, false)
autocor(xm) # not defined 
x1 = autocor([1,2])
@handlemissings2(autocor, true)
autocor(xm)

using MacroTools
x = [1.0,2.0,missing]

function f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true)
    @info "original method with Vector(Real)"
    @show x,typeof(x),lags,demean
    x
end

@expand @handlemissings(
    f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    #f16(x::AbstractVector{<:Real}; demean=true) = 1,
    1,2,AbstractVector{<:Union{Missing,Real}},
    (mgen.missingstrategy_nonsuperofeltype, mgen.passmissing_convert, mgen.handlemissing_collect_skip),
    PassMissing(),
)


@handlemissings(
    f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    #f16(x::AbstractVector{<:Real}; demean=true) = 1,
    1,2,AbstractVector{<:Union{Missing,Real}},
    (mgen.passmissing_convert, mgen.handlemissing_collect_skip),
    PassMissing(),
)

#methods(f11_hm100)
f11_hm100(PassMissing(), x)
f16(x, PassMissing())
f16(x[1:2], PassMissing())
f11_hm100(SkipMissing(), x)
f16(x, SkipMissing(); demean=false)
f16([1.,2], PassMissing())
f16(x; demean=false)

d = Dict(:a=>1, :b=>2)
macro m1(d)
    @show d
    quote
        $d[:a]
    end
end
@macroexpand @m1(d)
@m1 d

using MissingStrategies.mgen
using MacroTools

# macro withinfo
d = Dict(:a=1, :b=2)
tmp1 = :(mgen.@forwarder 1)
@eval $tmp1
tmp2 = @eval mgen.@withinfo(mgen.var"@forwarder", $d)
@eval $tmp2

f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = x

info = mgen.@getdispatchinfo(
    f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    #f16(x::AbstractVector{<:Real}; demean=true) = 1,
    1,2,AbstractVector{<:Union{Missing,Real}},
    PassMissing(),
)

@expand mgen.@getdispatchinfo(
    f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
    #f16(x::AbstractVector{<:Real}; demean=true) = 1,
    1,2,AbstractVector{<:Union{Missing,Real}},
    PassMissing(),
)

function m1(fun, gens = (mgen.forwarder, mgen.missingstrategy_notsuperofeltype))
    dinfo = mgen.getdispatchinfo(
        fun,
        1,2,AbstractVector{<:Union{Missing,Real}},
        PassMissing(),
    )
    # quote
    #     $(mgen.forwarder(;d...))
    #     $(mgen.missingstrategy_notsuperofeltype(;d...))
    # end
    exp = ntuple(i->gens[i](;dinfo...), length(gens))
    Expr(:block, exp...)
end
m1(
    :(f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1)
)
macro m1(fun); m1(fun);m1(fun) end
@expand @m1(
    f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
)
tmp2 = @m1(
    f16(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer} = 1:3; demean=true) = 1,
)


x = [1.0, 2.0]
f16(x, PassMissing())
