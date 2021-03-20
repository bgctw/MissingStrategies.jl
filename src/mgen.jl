"""
Submodule defining functions that generate specific methods that handle missings.
They are called from within[`@handlemissings`](@ref).
"""
module mgen
using MissingStrategies
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

function missingstrategy_nonsuperofeltype(
  dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses
  )
  fname_orig = esc(dict_forig[:name])
  body = quote
      # call forig withoug any modification
      $fname_orig($(argnames...);$(kwargpasses...)) 
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses,
    MissingStrategy, :(!(IsEltypeSuperOfMissing)), body
  )
end  

function passmissing_nonconvert(
  dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses
  )
  fname_orig = esc(dict_forig[:name])
  body = quote
    any(ismissing.($xname)) && return missing
    $fname_orig($(argnames...);$(kwargpasses...)) 
  end
  traitfun_missingstrategy(
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses,
    PassMissing, :(IsEltypeSuperOfMissing), body
  )
end  

function passmissing_convert(
  dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses
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
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses,
    PassMissing, :(IsEltypeSuperOfMissing), body
  )
  # args = dict_forig[:args]
  # xname = argnames[pos_missing]
  # fname_orig = esc(dict_forig[:name])
  # quote
  #   @traitfn function $fname_disp($argstrat::PassMissing,
  #     $(args[1:(pos_missing-1)]...),
  #     $(xname)::::IsEltypeSuperOfMissing,
  #     $(args[(pos_missing+1):end]...);
  #     $(dict_forig[:kwargs]...)
  #     ) where {$(dict_forig[:whereparams]...)}
  #     any(ismissing.($xname)) && return missing
  #     x1nm = convert.(nonmissingtype(eltype($xname)),$xname)
  #     Missing <: typeof(x1nm) && error("could not convert to nonmissing type") 
  #     $fname_orig(
  #       $(argnames[1:(pos_missing-1)]...),
  #       x1nm,
  #       $(argnames[(pos_missing+1):end]...);
  #       $(kwargpasses...)
  #     )
  #   end # traitfn
  # end # quote
end  

function handlemissing_collect_skip(
  dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses
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
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses,
    HandleMissingStrategy, :(IsEltypeSuperOfMissing), body
  )
  # args = dict_forig[:args]
  # xname = argnames[pos_missing]
  # fname_orig = esc(dict_forig[:name])
  # quote
  #   @traitfn function $fname_disp($argstrat::HandleMissingStrategy,
  #     $(args[1:(pos_missing-1)]...),
  #     $(xname)::::IsEltypeSuperOfMissing,
  #     $(args[(pos_missing+1):end]...);
  #     $(dict_forig[:kwargs]...)
  #     ) where {$(dict_forig[:whereparams]...)}
  #     x1nm = collect(skipmissing($xname))
  #     $fname_orig(
  #       $(argnames[1:(pos_missing-1)]...),
  #       x1nm,
  #       $(argnames[(pos_missing+1):end]...);
  #       $(kwargpasses...)
  #     )
  #   end # traitfn
  # end # quote
end  

function handlemissing_skip(  
  dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses
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
    dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses,
    HandleMissingStrategy, :(IsEltypeSuperOfMissing), body
  )
end  

function traitfun_missingstrategy(
  dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses
  # avoid redundancy in method specification, only provide three more arguments
  ,MissingStrategyType, xTrait, body)
  args = dict_forig[:args]
  xname = argnames[pos_missing]
  quote
      @traitfn function $fname_disp($argstrat::$MissingStrategyType,
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
