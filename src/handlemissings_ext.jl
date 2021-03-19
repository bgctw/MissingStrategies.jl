macro m2(fun,pos_missing=1, pos_strategy=pos_missing +1, argstrat=:ms, salt=100)
  dict = splitdef(fun)
  # add MissingStrategy argument at first position for extended 
  args = dict[:args]
  args_names = first.(splitarg.(args))
  @show args_names
  #pushfirst!(argsex, :($argstrat::MissingStrategy))
  # add MissingStrategy argument at pos_strategy 
  argsext = copy(dict[:args])
  insert!(argsext, pos_strategy, :($argstrat::MissingStrategy))
  rtype = get(dict, :rtype, :Any)
  # forwarding to a function with extended name for which we can apply @traitfun
  fname = esc(dict[:name])
  fname_disp = esc(Symbol(String(dict[:name]) * "_hm$salt"))
  quote
function $fname($(argsext...); kwargs...)::$rtype where {$(dict[:whereparams]...)}
  $fname_disp($argstrat, $(args_names...); kwargs...)
end
function $fname_disp($argstrat::MissingStrategy, $(args...); $(dict[:kwargs]...))::$rtype where {$(dict[:whereparams]...)}
  $argstrat
end
  end # quote
end
