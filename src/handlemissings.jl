macro m1(fun)
  @info "m1"
  dump(fun)
  fun
end

macro m2(fun,pos_missing=1, pos_strategy=pos_missing +1, argstrat=:ms, salt=100)
  dict_forig = splitdef(fun)
  # add MissingStrategy argument at first position for extended 
  args = dict_forig[:args]
  argnames = first.(splitarg.(args))
  # add MissingStrategy argument at pos_strategy 
  argsext = copy(dict_forig[:args])
  insert!(argsext, pos_strategy, :($argstrat::MissingStrategy))
  # is strategy argument is inserted before missing argument adjust position TODO:test
  if pos_missing >= pos_strategy; pos_missing += 1; end
  # remove type from argument in question
  argsext[pos_missing] = splitarg(argsext[pos_missing])[1]
  rtype = get(dict_forig, :rtype, :Any)
  # forwarding to a function with extended name for which we can apply @traitfun
  fname = esc(dict_forig[:name])
  fname_disp = esc(Symbol(String(dict_forig[:name]) * "_hm$salt"))
  xname = first(splitarg(args[pos_missing]))
  kwargpasses = passkwargs(dict_forig[:kwargs])
  gens = (Generators.pass_convert_missing, Generators.handle_collect_skip_missing)
  #fmiss = (dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses)
  #fskip = (dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses)
  fstrats = map(gen -> gen(dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses),gens)
  quote
function $fname($(argsext...); kwargs...)::$rtype where {$(dict_forig[:whereparams]...)}
  $fname_disp($argstrat, $(argnames...); kwargs...)
end
$(fstrats...)
  end # quote
end

function passkwargs(kwargs)
  map(x -> esc(:($x = $x)), first.(splitarg.(kwargs)))
end

module Generators

function pass_missing(dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses)
  args = dict_forig[:args]
  xname = argnames[pos_missing]
  fname_orig = esc(dict_forig[:name])
  quote
    @traitfn function $fname_disp($argstrat::PassMissing,
      $(args[1:(pos_missing-1)]...),
      $(xname)::::IsEltypeSuperOfMissing,
      $(args[(pos_missing+1):end]...);
      $(dict_forig[:kwargs]...)
      ) where {$(dict_forig[:whereparams]...)}
      any(ismissing.($xname)) && return missing
      $fname_orig($(argnames...);$(kwargpasses...)) 
    end # traitfn
  end # quote
end  

function pass_convert_missing(dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses)
  args = dict_forig[:args]
  xname = argnames[pos_missing]
  fname_orig = esc(dict_forig[:name])
  quote
    @traitfn function $fname_disp($argstrat::PassMissing,
      $(args[1:(pos_missing-1)]...),
      $(xname)::::IsEltypeSuperOfMissing,
      $(args[(pos_missing+1):end]...);
      $(dict_forig[:kwargs]...)
      ) where {$(dict_forig[:whereparams]...)}
      any(ismissing.($xname)) && return missing
      x1nm = convert.(nonmissingtype(eltype($xname)),$xname)
      Missing <: typeof(x1nm) && error("could not convert to nonmissing type") 
      $fname_orig(
        $(argnames[1:(pos_missing-1)]...),
        x1nm,
        $(argnames[(pos_missing+1):end]...);
        $(kwargpasses...)
      )
    end # traitfn
  end # quote
end  

function handle_collect_skip_missing(dict_forig, fname_disp, argstrat, argnames, pos_missing, kwargpasses)
  args = dict_forig[:args]
  xname = argnames[pos_missing]
  fname_orig = esc(dict_forig[:name])
  quote
    @traitfn function $fname_disp($argstrat::HandleMissingStrategy,
      $(args[1:(pos_missing-1)]...),
      $(xname)::::IsEltypeSuperOfMissing,
      $(args[(pos_missing+1):end]...);
      $(dict_forig[:kwargs]...)
      ) where {$(dict_forig[:whereparams]...)}
      x1nm = collect(skipmissing($xname))
      $fname_orig(
        $(argnames[1:(pos_missing-1)]...),
        x1nm,
        $(argnames[(pos_missing+1):end]...);
        $(kwargpasses...)
      )
    end # traitfn
  end # quote
end  


end # module Generators
