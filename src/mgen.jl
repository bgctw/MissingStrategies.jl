"""
Submodule defining functions that generate specific methods that handle missings.
They are called from within [`handlemissings`](@ref).

The keyword arguments of the generator functions correspond to entries in 
[`getdispatchinfo`](@ref).
"""
module mgen
using MissingStrategies
using MacroTools
using SimpleTraits

function test(fname = :test5)
  #fname = esc(:temp4)
  quote
    function $(esc(fname))()
       "in " * String($(esc(fname)))
    end
  end
end

"""
    forwarder(...)

Defines a method with new type of missing argument and MissingStrategy inserted
forwarding to dispatching function of new name with MissingStrategy at first position.
"""
function forwarder(;
    dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
    pos_strategy, argname_strategy, defaultstrategy

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
  ad_nodefault = :($argname_strategy::MissingStrategy)
  argstratdef = (isnothing(defaultstrategy) || defaultstrategy == :nothing) ? 
    ad_nodefault : Expr(:kw, ad_nodefault, defaultstrategy)
  insert!(argsmext, pos_strategy, argstratdef)
  fname = dict_forig[:name]
  #QuoteNode(
  :(function $fname($(argsmext...); kwargs...) where {$(dict_forig[:whereparams]...)}
    #:(function $(esc(fname))($(argsmext...); kwargs...) where {$(dict_forig[:whereparams]...)}
    #$(esc(fname_disp))($argname_strategy, $(argnames...); kwargs...)
    $fname_disp($argname_strategy, $(argnames...); kwargs...)
  end)  
  #)
end

"""
    missingstrategy_notsuperofeltype(...)

Defines a trait method for any MissingStrategy for arguments whose eltype does not allow
  missing. This just forwards to the original function.
"""
function missingstrategy_notsuperofeltype(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, argname_strategy, defaultstrategy
  )
  #fname_orig = esc(dict_forig[:name])
  #fname_orig = esc(dict_forig[:name])
  fname_orig = dict_forig[:name]
  body = quote
      # call forig without any modification
      $fname_orig($(argnames...);$(kwargpasses...)) 
  end
  #return QuoteNode(fname_disp)
  #QuoteNode(
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, argname_strategy, kwargpasses,
    :MissingStrategy, :(!(IsEltypeSuperOfMissing)), body
  )
  #)
end  

"""
    passmissing_nonconvert(...)

Defines a trait method for `PassMissing` for arguments whose eltype allowing missing.
This method returns missing if any missing items are encoured or otherwise
calls the original function with non-modified arguments, i.e. with type that 
allows missings in its eltype.
"""
function passmissing_nonconvert(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy,  argname_strategy, defaultstrategy

  )
  #fname_orig = esc(dict_forig[:name])
  fname_orig = dict_forig[:name]
  xname = argnames[pos_missing]
  body = quote
    any(ismissing.($xname)) && return missing
    $fname_orig($(argnames...);$(kwargpasses...)) 
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argnames, pos_missing, argname_strategy, kwargpasses,
    :PassMissing, :(IsEltypeSuperOfMissing), body
  )
end  

"""
    passmissing_convert(...)

Defines a trait method for `PassMissing` for arguments whose eltype allowing missing.
This method returns missing if any missing items are encoured or otherwise
calls the original function, but converts the argument to the corresponding
nonmissing type.
"""
function passmissing_convert(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, argname_strategy, defaultstrategy

  )
  #fname_orig = esc(dict_forig[:name])
  fname_orig = dict_forig[:name]
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
    dict_forig, fname_disp, argnames, pos_missing, argname_strategy, kwargpasses,
    :PassMissing, :(IsEltypeSuperOfMissing), body
  )
end  

"""
    handlemissing_collect_skip(...)

Defines a trait method for `HandleMissingStrategy` 
for arguments whose eltype allows missings.
This method transforms the argument by `collect(skipmissing(x))` before
passing it on to the original function.

Hence it passes a vector with corresponding nonmissing eltype, but does
require allocation.  
"""
function handlemissing_collect_skip(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, argname_strategy, defaultstrategy
  )
  #fname_orig = esc(dict_forig[:name])
  fname_orig = dict_forig[:name]
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
    dict_forig, fname_disp, argnames, pos_missing, argname_strategy, kwargpasses,
    :HandleMissingStrategy, :(IsEltypeSuperOfMissing), body
  )
end  

"""
    handlemissing_skip(...)

Defines a trait method for `HandleMissingStrategy` 
for arguments whose eltype allows missings.
This method transforms the argument by `skipmissing(x)` before
passing it on to the original function.

Hence it passes an itereator of undefined type but does not require allocations.  
"""
function handlemissing_skip(;
  dict_forig, fname_disp, argnames, kwargpasses, pos_missing, type_missing, 
  pos_strategy, argname_strategy, defaultstrategy

  )
  #fname_orig = esc(dict_forig[:name])
  fname_orig = dict_forig[:name]
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
    dict_forig, fname_disp, argnames, pos_missing, argname_strategy, kwargpasses,
    :HandleMissingStrategy, :(IsEltypeSuperOfMissing), body
  )
end  

"""
    traitfun_missingstrategy()

A helper function used by the generator functions that creates a proper method
  signature for the position of the argument that should handle missig values.   

In addition to arguments passed to the generator functions, it requires the following 
arguments:
- `MissingStrategyType`: the specific subtype of [`MissingStrategy`](@ref) to be matched
- `xTrait`: The Trait of the argument that shoudl handle missings. Usually either
    `:(IsEltypeSuperOfMissing)` or `:(!(IsEltypeSuperOfMissing))`.
- `body`: The body of the method to be generated.
"""
function traitfun_missingstrategy(
  dict_forig, fname_disp, argnames, pos_missing, argname_strategy, kwargpasses,
  # requires three more arguments compared to generator functions:
  MissingStrategyType::Union{Symbol,Expr}, xTrait, body
  )
  args = dict_forig[:args]
  xname = argnames[pos_missing]
  quote
      #@traitfn function $(esc(fname_disp))($argstratname::$MissingStrategyType,
      @traitfn function $fname_disp($argname_strategy::$MissingStrategyType,
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
