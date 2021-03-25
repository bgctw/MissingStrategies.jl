"""
Submodule defining functions that generate specific methods that handle missings.
They are called from within[`@handlemissings`](@ref).
"""
module mgen
using MissingStrategies
using MacroTools
using SimpleTraits

# export 
#   passmissing_nonconvert,
#   passmissing_convert,
#   handlemissing_collect_skip,
#   handlemissing_skip

function test(fname = :test5)
  #fname = esc(:temp4)
  quote
    function $(esc(fname))()
       "in " * String($(esc(fname)))
    end
  end
end

function getdispatchinfo(
  fun,
  pos_missing=1, pos_strategy=pos_missing +1, type_missing=Any,
  defaultstrategy=nothing, salt=100
  )
  dict_forig = splitdef(fun)
  fname_disp = Symbol(String(dict_forig[:name]) * "_hm$salt")
  argnames = first.(splitarg.(dict_forig[:args]))
  # forwarding to a function with extended name for which we can apply @traitfun
  #kwargpasses = map(x -> esc(:($x = $x)), first.(splitarg.(dict_forig[:kwargs])))
  kwargpasses = map(x -> :($(esc(x)) = $(esc(x))), first.(splitarg.(dict_forig[:kwargs])))
  Dict(
    :dict_forig => dict_forig,
    :fname_disp => fname_disp, 
    :argnames => argnames, 
    :kwargpasses => kwargpasses,
    :pos_missing => pos_missing, 
    :type_missing => type_missing,
    :pos_strategy => pos_strategy, 
    #:argstrat => argstrat, 
    :defaultstrategy => defaultstrategy,
    :salt => salt,
  )
end


"""
  @insert_strategyarg(info)

Defines a method with new returntype of missing argument and MissingStrategy inserted
forwarding to dispatching function of new name with MissingStrategy at first position.
"""
function forwarder(;
    dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
    pos_strategy, defaultstrategy, salt
  )
  # replace type from argument that should allow missings
  #dict_forig = MissingStrategies.unesc(dict_forig)
  #return fname_disp
  argsm = copy(dict_forig[:args])
  sarg = splitarg(argsm[pos_missing])
  argsm[pos_missing] = MacroTools.combinearg(sarg[1], type_missing, sarg[3:end]...)
  # add MissingStrategy argument at pos_strategy to extended argument list
  # argsext = copy(dict_forig[:args]) # with original missing type
  # insert!(argsext, pos_strategy, :(ms::MissingStrategy))
  argsmext = copy(argsm)
  argnamestrat = gensym("ms")
  ad_nodefault = :($argnamestrat::MissingStrategy)
  argstratdef = (isnothing(defaultstrategy) || defaultstrategy == :nothing) ? 
    ad_nodefault : Expr(:kw, ad_nodefault, defaultstrategy)
  insert!(argsmext, pos_strategy, argstratdef)
  fname = dict_forig[:name]
  #QuoteNode(
  :(function $(esc(fname))($(argsmext...); kwargs...) where {$(dict_forig[:whereparams]...)}
    $(esc(fname_disp))($argnamestrat, $(argnames...); kwargs...)
  end)  
  #)
end

function missingstrategy_notsuperofeltype(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, defaultstrategy, salt
  )
  #fname_orig = esc(dict_forig[:name])
  fname_orig = esc(dict_forig[:name])
  body = quote
      # call forig withoug any modification
      $fname_orig($(argnames...);$(kwargpasses...)) 
  end
  #return QuoteNode(fname_disp)
  #QuoteNode(
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, kwargpasses,
    MissingStrategy, :(!(IsEltypeSuperOfMissing)), body
  )
  #)
end  

function passmissing_nonconvert(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, defaultstrategy, salt
  )
  fname_orig = esc(dict_forig[:name])
  xname = argnames[pos_missing]
  body = quote
    any(ismissing.($xname)) && return missing
    $fname_orig($(argnames...);$(kwargpasses...)) 
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, kwargpasses,
    PassMissing, :(IsEltypeSuperOfMissing), body
  )
end  

function passmissing_convert(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, defaultstrategy, salt
  )
  fname_orig = esc(dict_forig[:name])
  xname = argnames[pos_missing]
  body = quote
    any(ismissing.($xname)) && return missing
    x1nm = convert.(nonmissingtype(eltype($xname)),$xname)
    Missing <: typeof(x1nm) && error("could not convert to nonmissing type") 
    $fname_orig(
      $(argnames[1:(pos_missing-1)]...),
      x1nm,
      $(argnames[(pos_missing+1):end]...);
      $(kwargpasses...)
    )
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, kwargpasses,
    PassMissing, :(IsEltypeSuperOfMissing), body
  )
end  

function handlemissing_collect_skip(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, defaultstrategy, salt
  )
  fname_orig = esc(dict_forig[:name])
  xname = argnames[pos_missing]
  body = quote
    x1nm = collect(skipmissing($xname))
    $fname_orig(
      $(argnames[1:(pos_missing-1)]...),
      x1nm,
      $(argnames[(pos_missing+1):end]...);
      $(kwargpasses...)
    )
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, kwargpasses,
    HandleMissingStrategy, :(IsEltypeSuperOfMissing), body
  )
end  

function handlemissing_skip(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, defaultstrategy, salt
  )
  fname_orig = esc(dict_forig[:name])
  xname = argnames[pos_missing]
  body = quote
    x1nm = skipmissing($xname)
    $fname_orig(
      $(argnames[1:(pos_missing-1)]...),
      x1nm,
      $(argnames[(pos_missing+1):end]...);
      $(kwargpasses...)
    )
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, kwargpasses,
    HandleMissingStrategy, :(IsEltypeSuperOfMissing), body
  )
end  

function traitfun_missingstrategy(
  dict_forig, fname_disp, argnames, pos_missing, kwargpasses,
  # avoid redundancy in method specification, only provide three more arguments
  MissingStrategyType, xTrait, body)
  args = dict_forig[:args]
  xname = argnames[pos_missing]
  argstratname = gensym("ms")
  quote
      @traitfn function $(esc(fname_disp))($argstratname::$MissingStrategyType,
          $(args[1:(pos_missing-1)]...),
          $(xname)::::$xTrait, 
          $(args[(pos_missing+1):end]...);
          $(dict_forig[:kwargs]...)
          ) where {$(dict_forig[:whereparams]...)}
          $body
      end # traitfn
  end # quote
end # traitfun_missingstrategy


end # module mgen
