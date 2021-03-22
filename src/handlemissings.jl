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
  # need to give gens as an expression here to match passing by argument
  gens = :((mgen.passmissing_convert, mgen.handlemissing_collect_skip)),
  argstrat=:ms, salt=100,
  )
  if isnothing(type_missing)
    warning("Expected `type_missing` argument to be specified. Using `Any`.")
    type_missing = Any
  end
  dict_forig = splitdef(fun)
  type_nonmissing = eval(splitarg(dict_forig[:args][pos_missing])[2])
  (type_nonmissing === Any || 
  SimpleTraits.istrait(IsEltypeSuperOfMissing{type_nonmissing})) && error(
      "Element type ($type_nonmissing) does not exclude missings. "*
      "Better use @handlemissings_any")
  handlemissings(fun, pos_missing, pos_strategy, type_missing,
      defaultstrategy, gens, argstrat, salt)
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
  defaultstrategy=nothing,
  gens = :((mgen.passmissing_nonconvert, mgen.handlemissing_skip)),
  argstrat=:ms, salt=100
  )
  dict_forig = splitdef(fun)
  type_nonmissing = eval(splitarg(dict_forig[:args][pos_missing])[2])
  !(eltype(type_nonmissing) == Any) || 
  SimpleTraits.istrait(IsEltypeSuperOfMissing{type_nonmissing}) && @warn(
      "Element type ($type_nomissing) does not accept missings. " *
      "Did you want to use handlemissings_any?")
  !isnothing(defaultstrategy) && @warn(
    "Specified default strategy, but this will not be called, because original " *
    "method method matches alreay.")
  handlemissings(fun, pos_missing, pos_strategy, type_missing,
    defaultstrategy, gens, argstrat, salt)
end

"""
  @handlemissings

Defines new methods that allow missings in the eltype of an argument.

# Arguments
TODO

For examples see specialized versions with different argument defaults
- [`handlemissings_typed`](@ref) suitable if the type of the original method does not allow
  missing value
- [`handlemissings_any`](@ref) suitable if the type of the original method does allow
  missing value. 
"""
macro handlemissings(
  fun,
  pos_missing=1, pos_strategy=pos_missing +1, type_missing=Any,
  defaultstrategy=nothing, 
  gens=:(()),
  argstrat=:ms, salt=100
  )
  handlemissings(fun, pos_missing, pos_strategy, type_missing,
    defaultstrategy, gens, argstrat, salt)
end

function handlemissings(
  fun,
  pos_missing=1, pos_strategy=pos_missing +1, type_missing=Any,
  defaultstrategy=nothing, 
  gens=(),
  argstrat=:ms, salt=100
  )
  #@info "handlemissings"
  # fun, pos_missing, pos_strategy, pos_missing, type_missing, gens, 
  # defaultstrategy, argstrat, salt = unesc.((
  #   fun, pos_missing, pos_strategy, pos_missing, type_missing, gens, 
  #   defaultstrategy, argstrat, salt))
  dict_forig = splitdef(fun)
  argsm = copy(dict_forig[:args])
  argnames = first.(splitarg.(argsm))
  # replace type from argument in question
  sarg = splitarg(argsm[pos_missing])
  argsm[pos_missing] = MacroTools.combinearg(sarg[1], type_missing, sarg[3:end]...)
  # add MissingStrategy argument at pos_strategy to extended argument list
  # argsext = copy(dict_forig[:args]) # with original missing type
  # insert!(argsext, pos_strategy, :($argstrat::MissingStrategy))
  argsmext = copy(argsm)
  ad_nodefault = :($argstrat::MissingStrategy)
  argstratdef = (isnothing(defaultstrategy) || defaultstrategy == :nothing) ? 
    ad_nodefault : Expr(:kw, ad_nodefault, defaultstrategy)
  insert!(argsmext, pos_strategy, argstratdef)
  # forwarding to a function with extended name for which we can apply @traitfun
  fname = esc(dict_forig[:name])
  fname_disp = esc(Symbol(String(dict_forig[:name]) * "_hm$salt"))
  xname = first(splitarg(argsm[pos_missing]))
  kwargpasses = map(x -> esc(:($x = $x)), first.(splitarg.(dict_forig[:kwargs])))
  fbase = :(
# method with new returntype of missing argument and MissingStrategy inserted
# forwarding to function of new name with MissingStrategy at first position    
function $fname($(argsmext...); kwargs...) where {$(dict_forig[:whereparams]...)}
  $fname_disp($argstrat, $(argnames...); kwargs...)
end)
  # TODO ask how to avoid eval
  #@show gens
  fstrats = Tuple(eval(gen)(
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses) 
    for gen in (mgen.missingstrategy_nonsuperofeltype, gens.args...))
  #fstrats = [()] # debugging
  Expr(:block,fbase, unblock.(fstrats)...)
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
