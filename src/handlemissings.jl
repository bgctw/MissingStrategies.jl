"""
  @handlemissings_typed

Calling `@handlemissings` with defaults tailored to an original method where the 
eltype does not accepts missings.
- Argument type of the new function must be specified. May use `Any`.
- PassMissing method calls the original method with an broadcast where each element has been
  converted to the corresponding nonmissing type
  (`mgen.`[`passmissing_convert`](@ref)).
- SkipMissing method collects the skipmissing object before calling the original function
  (`mgen.`[`handlemissing_collect_skip`](@ref)).
- A default method (without `MissingStrategy` argument) is created that forwards to the 
  PassMissing method.

# Note on default MissingStrategy
Note, that defining a default Missingstrategy at an argument position before further 
optional arguments behaves in a way that was not intuitive. 
```julia
f1(x::AbstractArray{<:Real},optarg=1:3) = x
@handlemissings_typed(f1(x::AbstractArray{<:Real},optarg=1:3)=0,1,2,Any)
# f1(x,ms::MissingStrategy=PassMissing(),optarg=1:3) # generated
f1([1.0,missing], 2:4) # no method defined, rething argument ordering
```
In the above case you would need to call @handle_missing_typed separately
for the method with a single and the method with two arguments to achieve 
calling PassMissing variant and place the default missing strategy behind
the second argument.
```julia
f3(x::AbstractArray{<:Real},optarg=1:3) = x
@handlemissings_typed(f3(x::AbstractArray{<:Real})=0,1,2,Any)
@handlemissings_typed(f3(x::AbstractArray{<:Real}, optarg)=0,1,3,Any)
ismissing(f3([1.0,missing], 2:4))
```
"""
macro handlemissings_typed(
  fun,pos_missing=1, pos_strategy=pos_missing +1, type_missing=nothing,
  defaultstrategy=PassMissing(), 
  argstrat=:ms, salt=100,
  )
  # cannot pass functions by parameters, because they would only be symbols
  gens = (
    mgen.forwarder, mgen.missingstrategy_notsuperofeltype,
    mgen.passmissing_convert, mgen.handlemissing_collect_skip)
  if isnothing(type_missing)
    warning("Expected `type_missing` argument to be specified. Using `Any`.")
    type_missing = Any
  end
  expm = handlemissings(fun, pos_missing, pos_strategy, type_missing,
      defaultstrategy, gens, salt)
  dict_forig = splitdef(fun)
  type_nonmissing = splitarg(dict_forig[:args][pos_missing])[2]
  quote
      ($type_nonmissing === Any || 
      SimpleTraits.istrait(IsEltypeSuperOfMissing{$type_nonmissing})) && error(
          "Element type (" * $type_nonmissing * ") does not exclude missings. " *
          "Better use @handlemissings_any")
     $expm
  end
end

"""
  @handlemissings_any

Calling `@handlemissings` with defaults tailored to an original method where the 
eltype accepts missings already.
- Agument type of the new function is set to the same as the original method.
- PassMissing methods calls the original directly without convert the type
  (`mgen.`[`passmissing_nonconvert`](@ref)).
- HandleMissing methods calls the original directly with the `skipmissing()` object.
- No default method (without the `MissingStragety` argument) is created.
  (`mgen.`[`handlemissing_skip`](@ref)).

Note, that if the original method allows `missing` in `eltype`, you need to explicitly
pass the `PassMissing()` strategy. A potential default method would match the original
method and either not be called at all or call itself recursively causing an infinite loop.
"""
macro handlemissings_any(
  fun, pos_missing=1, pos_strategy=pos_missing +1, type_missing=Any,
  defaultstrategy=nothing, salt=100,
  )
  gens = (
    mgen.forwarder, mgen.missingstrategy_notsuperofeltype,
    mgen.passmissing_nonconvert, mgen.handlemissing_skip)
  !isnothing(defaultstrategy) && @warn(
    "Specified default strategy, but this will not be called, because original " *
    "method method matches alreay.")
  expm = handlemissings(fun, pos_missing, pos_strategy, type_missing,
    defaultstrategy, gens, salt)
  dict_forig = splitdef(fun)
  type_nonmissing = splitarg(dict_forig[:args][pos_missing])[2]
  quote
    !(eltype($type_nonmissing) == Any) || 
    SimpleTraits.istrait(IsEltypeSuperOfMissing{$type_nonmissing}) && @warn(
        "Element type (" * $type_nonmissing * ") does not accept missings. " *
        "Did you want to use handlemissings_any?")
    $expm
  end
end

"""
  handlemissings(fun, ...)

Creates an expression that defines new methods that allow missings in the 
eltype of an argument.

# Arguments
- `fun`: Expression of a functin signature
-  TODO

For examples see specialized macros
- [`@handlemissings_typed`](@ref) suitable if the type of the original method does not allow
  missing value
- [`@handlemissings_any`](@ref) suitable if the type of the original method does allow
  missing value. 
"""
function handlemissings(
  fun,
  pos_missing=1, pos_strategy=pos_missing +1, type_missing=Any,
  defaultstrategy=nothing, 
  gens=:(()),
  argstrat=:ms, salt=100
  )
  dinfo = mgen.getdispatchinfo(
    fun, 
    pos_missing, pos_strategy, type_missing,
    defaultstrategy, salt
  )
  # quote
  #     $(mgen.forwarder(;dinfo...))
  #     $(mgen.missingstrategy_notsuperofeltype(;dinfo...))
  # end
  exp = ntuple(i->gens[i](;dinfo...), length(gens))
  Expr(:block, exp...)
end


"""
    unesc(expr)

Remove outer `escape` blocks from an expression.
"""
unesc(ex) = ex
function unesc(ex::Expr)
  ex.head != :escape && return ex
  unesc(ex.args[1])
end


