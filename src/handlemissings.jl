"""
  @handlemissings_typed

Calling `@handlemissings` with defaults tailored to an original method where the 
eltype does not accepts missings.
- Argument type of the new function must be specified. May use `Any`.
- PassMissing method calls the original method with an broadcast where each element has been
  converted to the corresponding nonmissing type
- SkipMissing method collects the skipmissing object before calling the original function
- A default method (without `MissingStrategy` argument) is created that forwards to the 
  PassMissing method.
"""
macro handlemissings_typed(
  fun,pos_missing=1, pos_strategy=pos_missing +1, 
  type_missing=nothing,
  gens = (mgen.passmissing_convert, mgen.handlemissing_collect_skip),
  argstrat=:ms, salt=100,
  )
  if isnothing(type_missing)
    warning("Expected `type_missing` argument to be specified. Using `Any`.")
    type_missing = Any
  end
  dict_forig = splitdef(fun)
  type_nonmissing = splitarg.(dict_forig[:args][pos_missing])
  @show type_nonmissing
  #SimpleTraits.istrait(IsEltypeSuperOfMissing{type_nomissing})
  #@handlemissings(fun,pos_missing, pos_strategy, type_missing, gens, argstrat, salt)
end

"""
  @handlemissings_any

Calling `@handlemissings` with defaults tailored to an original method where the 
eltype accepts missings already.
- Agument type of the new function is set to the same as the original method.
- PassMissing methods calls the original directly without convert the type.
- HandleMissing methods calls the original directly with the `skipmissing()` object.
- No default method (without the `MissingStragety` argument) is created.
"""
macro handlemissings_any(
  fun,pos_missing=1, pos_strategy=pos_missing +1, 
  type_missing=nothing,
  gens = (mgen.passmissing_nonconvert, mgen.handlemissing_skip),
  argstrat=:ms, salt=100
  )
  dict_forig = splitdef(fun)
  type_nonmissing = splitarg.(dict_forig[:args][pos_missing])
  @show type_nonmissing
  #SimpleTraits.istrait(IsEltypeSuperOfMissing{type_nomissing})
  #@handlemissings(fun,pos_missing, pos_strategy, type_missing, gens, argstrat, salt)
end

"""
This macro defines a new function and subsequently methods that need to dispatch on it.
The subsequent definitions do not work until execution has reached top-level again 
(world age problem.)
Hence, the macro must be called twice from the top level in order to work properly.
"""
macro handlemissings(
  fun,
  pos_missing=1, pos_strategy=pos_missing +1, type_missing=Any,
  gens=(),
  defaultstrategy=nothing, 
  argstrat=:ms, salt=100
  )
  dict_forig = splitdef(fun)
  argsm = copy(dict_forig[:args])
  argnames = first.(splitarg.(argsm))
  # replace type from argument in question
  sarg = splitarg(argsm[pos_missing])
  argsm[pos_missing] = MacroTools.combinearg(sarg[1], type_missing, sarg[3:end]...)
  rtype = get(dict_forig, :rtype, :Any)
  # add MissingStrategy argument at pos_strategy to extended argument list
  # argsext = copy(dict_forig[:args]) # with original missing type
  # insert!(argsext, pos_strategy, :($argstrat::MissingStrategy))
  argsmext = copy(argsm)
  @show defaultstrategy
  ad_nodefault = :($(esc(argstrat))::MissingStrategy)
  argstratdef = isnothing(defaultstrategy) ?  ad_nodefault : Expr(:kw,
    ad_nodefault, defaultstrategy)
  @show argstratdef
  @show argsmext
  insert!(argsmext, pos_strategy, argstratdef)
  # forwarding to a function with extended name for which we can apply @traitfun
  fname = esc(dict_forig[:name])
  fname_disp = esc(Symbol(String(dict_forig[:name]) * "_hm$salt"))
  xname = first(splitarg(argsm[pos_missing]))
  kwargpasses = map(x -> esc(:($x = $x)), first.(splitarg.(dict_forig[:kwargs])))
  # XX do not use eval: post how to do this properly
  #ans = Expr(:block,fstrats...)
  # fs = :(mgen.test, mgen.test)
  # fquotes = Tuple(eval(fsym)() for fsym in fs.args)
  # ans = Expr(:block,unblock.(fquotes)...)
  fbase = 
  quote
# method with new returntype of missing argument and MissingStrategy inserted
# forwarding to function of new name with MissingStrategy at first position    
function $fname($(argsmext...); kwargs...)::$rtype where {$(dict_forig[:whereparams]...)}
  $fname_disp($argstrat, $(argnames...); kwargs...)
end
  end # quote
  fstrats = Tuple(eval(gen)(
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses) 
    for gen in (mgen.missingstrategy_nonsuperofeltype, gens.args...))
  Expr(:block,fbase, unblock.(fstrats)...)
end
