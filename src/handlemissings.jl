"""
  @handlemissings_stub(fun, ...)

Calling [`handlemissings`](@ref) with just creating the disaptching matches but
no implementations yet that handling missings.
- Default to using argument type Any and providing no default strategy 
  (use arguments to change this.)
- Method with inserted MissingStrategy argument that forwards to the dispatching function
- A dispaching method for eltypes not allowing for missings for any MissingStrategy
  that calls the original function without the MissingStrategy.

Arguments: see [`handlemissings`](@ref)    

One then can define the other methods yourself using Simpletraits `@traitfn`.
```jldoctest; output=false
using SimpleTraits
f1(x::AbstractArray{<:Real}) = "method that is not accepting missings in eltype"
@handlemissings_stub(
  # signature matching that of the original function to be called
  f1(x::AbstractArray{<:Real}) = 0,
  # pos_missing, pos_strategy, type_missing, defaultstrategy
  1,2,AbstractArray{<:Union{Missing,Real}}, PassMissing()
) 
methods(f1) # just to see that new methods have been defined
# the new methods forward to new function f1_hm that can be extended for special cases
# note the argument order: missing strategy comes first in the dispatching function
@traitfn function f1_hm(ms::PassMissing, x::::IsEltypeSuperOfMissing) 
  "method handling missings in eltype"
end
f1([1.0,2.0]) == "method that is not accepting missings in eltype"
f1([1.0,2.0], PassMissing()) == "method that is not accepting missings in eltype"
f1([1.0,2.0,missing]) == "method handling missings in eltype"
# output
true
```
"""
macro handlemissings_stub(
  fun,pos_missing=1, pos_strategy=pos_missing +1, type_missing=:Any,
  defaultstrategy=:nothing, argname_strategy=:ms, suffix="_hm",
  )
  gens = (mgen.forwarder, mgen.missingstrategy_notsuperofeltype)
  esc(handlemissings(fun, pos_missing, pos_strategy, type_missing,
      defaultstrategy, gens, argname_strategy, suffix))
end

"""
  @handlemissings_typed(fun, ...)

Calling [`handlemissings`](@ref) with defaults tailored to an original method where the 
eltype does not accepts missings:
- Dispatching methods as with [`@handlemissings_stub`](@ref)
- Argument type of the new function must be specified. May use `Any`.
  A default method (without `MissingStrategy` argument) is created that forwards to the 
  PassMissing method. Hence, Make sure that the argument type differs from the original
  method so that the original method its not overwritten.
- PassMissing method calls the original method with an broadcast where each element has been
  converted to the corresponding nonmissing type
  ([`mgen.passmissing_convert`](@ref)).
- SkipMissing method collects the skipmissing object before calling the original function
  ([`mgen.handlemissing_collect_skip`](@ref)).

Arguments: see [`handlemissings`](@ref)    

# Note on default MissingStrategy
Note, that defining a default Missingstrategy at an argument position before further 
optional arguments behaves in a way that may not be intuitive.
```julia
f2(x::AbstractArray{<:Real},optarg=1:3) = x
@handlemissings_typed(f2(x::AbstractArray{<:Real},optarg=1:3)=0,1,2,Any)
# f2(x,ms::MissingStrategy=PassMissing(),optarg=1:3) # generated
# f2([1.0,missing], 2:4) # no method defined -> rethink argument ordering
```
In order to call the PassMissing variant in the above case, one would need to 
call `@handle_missing_typed` separately
for the method with a single and the method with two arguments 
and place the default missing strategy behind the second argument in the second case.
```julia
f3(x::AbstractArray{<:Real},optarg=1:3) = x
@handlemissings_typed(f3(x::AbstractArray{<:Real})=0,1,2,Any)
@handlemissings_typed(f3(x::AbstractArray{<:Real}, optarg)=0,1,3,Any)
ismissing(f3([1.0,missing], 2:4))
```
"""
macro handlemissings_typed(
  fun,pos_missing=1, pos_strategy=pos_missing +1, type_missing=:nothing,
  defaultstrategy=Meta.parse("PassMissing()"), argname_strategy=:ms, suffix="_hm"
,
  )
  # cannot pass functions by parameters, because they would only be symbols
  gens = (
    mgen.forwarder, mgen.missingstrategy_notsuperofeltype,
    mgen.passmissing_convert, mgen.handlemissing_collect_skip)
  if isnothing(type_missing)
    warning("Expected `type_missing` argument to be specified. Using `Any`.")
    type_missing = :(Any)
  end
  expm = handlemissings(fun, pos_missing, pos_strategy, type_missing,
      defaultstrategy, gens, argname_strategy, suffix)
  dict_forig = splitdef(fun)
  type_nonmissing = splitarg(dict_forig[:args][pos_missing])[2]
  esc(quote
      ($type_nonmissing === Any || 
      SimpleTraits.istrait(IsEltypeSuperOfMissing{$type_nonmissing})) && error(
          "Element type (" * $type_nonmissing * ") does not exclude missings. " *
          "Better use @handlemissings_any")
      $expm
  end)
end

"""
  @handlemissings_any(fun, ...)

Calling [`handlemissings`](@ref) with defaults tailored to an original method where the 
eltype accepts missings already:
- Dispatching methods as with [`@handlemissings_stub`](@ref)
- Agument type of the new function defaults to `Any`.
  No default method (without the `MissingStragety` argument) is created.
- PassMissing methods calls the original directly without converting the type of the 
  argument with missings ([`mgen.passmissing_nonconvert`](@ref)).
- HandleMissing methods calls the original directly with the `skipmissing()` 
  iterator object ([`mgen.handlemissing_skip`](@ref)).


Arguments: see [`handlemissings`](@ref)    

Note, that if the original method allows `missing` in `eltype`, you need to explicitly
pass the `PassMissing()` by argument. A potential default method would override the original
method and either not be called at all or call itself recursively causing an infinite loop.
"""
macro handlemissings_any(
  fun, pos_missing=1, pos_strategy=pos_missing +1, type_missing=:Any,
  defaultstrategy=:nothing, argname_strategy=:ms, suffix="_hm",
  )
  gens = (
    mgen.forwarder, mgen.missingstrategy_notsuperofeltype,
    mgen.passmissing_nonconvert, mgen.handlemissing_skip)
  !isnothing(defaultstrategy) && @warn(
    "Specified default strategy, but this will not be called, because original " *
    "method method matches alreay.")
  expm = handlemissings(fun, pos_missing, pos_strategy, type_missing,
    defaultstrategy, gens, argname_strategy, suffix)
  dict_forig = splitdef(fun)
  type_nonmissing = splitarg(dict_forig[:args][pos_missing])[2]
  esc(quote
    !(eltype($type_nonmissing) == Any) || 
    SimpleTraits.istrait(IsEltypeSuperOfMissing{$type_nonmissing}) && @warn(
        "Element type (" * $type_nonmissing * ") does not accept missings. " *
        "Did you want to use handlemissings_any?")
    $expm
  end)
end


"""
    handlemissings(fun, ...)

Creates an expression that defines new methods that allow missings in the 
eltype of an argument.

# Arguments
- `fun`: Expression of a function to extend
- `pos_missing = 1`: The postition of the argument that should handle missings
- `pos_strategy = pos_missing + 1`: The position at which the argument of MissingStrategy
   is to be inserted into the function signature
- `type_missing = :Any`: The new type of the argument that should handle missings.
   This can be an expression of the value.
- `defaultstrategy::Union{Nothing,MissingStrategy} = :nothing`: the value of the default 
  of the strategy argument. Use `:nothing` to indicate not specifying a default value.
  This can be an expression of the value.
- `gens = ()`: Tuple of generator functions (see [mgen]{@ref})
- `argname_strategy = :ms`: symbol of the argument name of the strategy argument
- `suffix="_hm"`: attached to the name of the dispatching function to avoid method
  ambiguities

Ususually this function is called from a macro that povide suitable dfault values
- [`@handlemissings_typed`](@ref) suitable if the type of the original method does not allow
  missing value
- [`@handlemissings_any`](@ref) suitable if the type of the original method does allow
  missing value. 
- [`@handlemissings_stub`](@ref) suitable for writing user-specified handling routines. 
"""
function handlemissings(
  fun,
  pos_missing::Int=1, pos_strategy::Int=pos_missing +1, type_missing=:Any,
  defaultstrategy=:nothing, 
  gens::Tuple=(),
  argname_strategy=:ms,
  suffix="_hm"
  )
  dinfo = getdispatchinfo(
    fun, 
    pos_missing, pos_strategy, type_missing,
    defaultstrategy, argname_strategy, suffix
  )
  # quote
  #     $(mgen.forwarder(;dinfo...))
  #     $(mgen.missingstrategy_notsuperofeltype(;dinfo...))
  # end
  exp = ntuple(i->gens[i](;dinfo...), length(gens))
  Expr(:block, exp...)
end

"""
    getdispatchinfo(...)

Collect information for dispatching non-missing types into a dictionary.

# Arguments
see [`handlemissings`](@ref).

# Return value
A dictionary with entries   
- `dict_forig`: dictionary result of MacroTools.splitdef(fun)
- `fname_disp`: Symbol of the dispatch function name, 
- `argnames`: the aguement names of fun, 
- `kwargpasses`: an Vector of expression of keyword parameters 'argname = argname'
- `pos_missing`: position of the argument that should handle missings, 
- `type_missing`: the new type of that argument,
- `pos_strategy`: the position at which the argument of MissingStrategy is inserted, 
- `defaultstrategy`: the default of that argument of type [`MissingStrategy`](@ref)
- `suffix="_hm"`: number to be appended to `fname_disp` to avoid method ambiguities,

These match the required argument for the method generators in module [`mgen`](@ref).
"""
function getdispatchinfo(
  fun,
  pos_missing::Int=1, pos_strategy::Int=pos_missing +1, type_missing=:Any,
  defaultstrategy=:nothing, 
  argname_strategy=:ms,
  suffix="_hm",
  )
  dict_forig = splitdef(fun)
  fname_disp = Symbol(String(dict_forig[:name]) * suffix)
  argnames = first.(splitarg.(dict_forig[:args]))
  # forwarding to a function with extended name for which we can apply @traitfun
  #kwargpasses = map(x -> esc(:($x = $x)), first.(splitarg.(dict_forig[:kwargs])))
  #kwargpasses = map(x -> :($(esc(x)) = $(esc(x))), first.(splitarg.(dict_forig[:kwargs])))
  kwargpasses = map(x -> :($x = $x), first.(splitarg.(dict_forig[:kwargs])))
  Dict(
    :dict_forig => dict_forig,
    :fname_disp => fname_disp, 
    :argnames => argnames, 
    :kwargpasses => kwargpasses,
    :pos_missing => pos_missing, 
    :type_missing => type_missing,
    :pos_strategy => pos_strategy, 
    :argname_strategy => argname_strategy,
    :defaultstrategy => defaultstrategy,
  )
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
