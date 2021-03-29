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

using MacroTools
x = [1.0,2.0,missing]

using MissingStrategies.mgen

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

f10(ms::Union{Nothing,MissingStrategy}) = isnothing(ms) ? nothing : something(ms)

f10(nothing)

using MissingStrategies
macro m1(tmp=:(PassMissing()))
    @show tmp, typeof(tmp)
    QuoteNode(tmp)
end
tmp2 = @m1()
tmp2 = @m1(PassMissing())
dump(Meta.parse("PassMissing()"))


module test
    macro m1()
        __module__
    end
    macro m1_esc()
        esc(__module__)
    end
    f1() = @m1
    f1_esc() = @m1_esc
end
test.@m1
test.f1()
test.f1_esc()

