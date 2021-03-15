"""
Trait which contains all types with Missing in element type, excluding Any".

This allows dispatching on any Collection (Iterator, Vector, Tuple) that
may contain missing elements.

See example of [`@handlemissings`](@ref) for an application.
"""
@traitdef IsEltypeSuperOfMissing{X}
iseltypesuperofmissing(X) = (eltype(X) !== Any) && (Missing <: eltype(X))
@traitimpl IsEltypeSuperOfMissing{X} <- iseltypesuperofmissing(X)


"""
    @handlemissings(fun, collectskipped=false, definedefault=false)
    
Define several methods for function `fun` 
that handle missing values in the elements of its first argument.

The second argument of the newly defined methods is of type [`MissingStrategies`](@ref).
The first argument is dispached on trait [`IsEltypeSuperOfMissing`](@ref)
- `@traitfun fun(x1::::IsEltypeSuperOfMissing, ::PassMissing, ...)` 
  returns missing if there is any missing element in x. 
  Otherwise, it converts the type of each element to the corresponding nonmissing type
  and calls the original function
- `@traitfun fun(x1::::IsEltypeSuperOfMissing, ::HandleMissingStrategy, ...)` 
  passes the first argument to [`skipmissing`](@ref) and optionally
  to [`collect`](@ref), before calling the original function.
- `@traitfun fun(x1::::!(IsEltypeSuperOfMissing), ::MissingStrategy, ...)` 
  calls the original function with unchanged `x1`. This allows passing both argument types,
  including and not including missings, to the method with a `MissingStrategy` argument.

# Notes  
By setting argument `definedefault=true` an additional method is defined:
- `@traitfun fun(x1::::IsEltypeSuperOfMissing, ...)` forwarding
  to the `fun(x1, PassMissing(), ...)` as a default for handling missings.
However, if the original method has no specific type attached, then this new
method is never called, but rather the original method is called.
Furthermore, this default method for missings 
creates methods which may accidentally match arguments for which the
original funciton threw an `No matching method error` and may cause indefine 
loop and StackOverFlow. Hence, its recommended to only define the default method,
if the original method explicitly constrains its type to non-missing.

For extending or overwritingn the defintitions created by `@handlemissings` the
[`IsEltypeSuperOfMissing`](@ref) trait is useful. 

Note, that supplying a generator to the first argument, 
does not work with @handlemissing, because `eltype(<generator>)` is `Any`. 
Use [`typediter`](@ref) to explicitly associate
an eltype, which may be a supertype of Missing.

# Examples
```jldoctest; output=false
# some function that cannot hanlde missing values yet
frealvec(xvec::AbstractVector{<:Real}) = xvec

@handlemissings(frealvec, true, true) # defines several new methods

# define specific subtype of HandleMissingStrategy explicitly 
using SimpleTraits
@traitfn function frealvec(x1::::IsEltypeSuperOfMissing, 
  ::ExactMissing, x...; kwargs...) 
  "return exact computation here"
end

frealvec([1,2]) # calls original method
xm = [1,2,missing]      # this argument caused a no-method defined error before for frealvec
frealvec(xm, PassMissing()) === missing
frealvec(xm, SkipMissing()) == frealvec([1,2]) 
frealvec(xm) === missing     # default method forwarding to PassMissing() 
#frealvec(1)       # beware: formerly "no method defined" now results in an indefinite loop
frealvec(xm, ExactMissing()) == "return exact computation here"
# output
true
```
"""
macro handlemissings(FUN, collectskipped=false, definedefault=false)
  x1nmskip = collectskipped ? :(collect(skipmissing(x1))) : :(skipmissing(x1))
  if definedefault 
    defaultmissingmethod = quote
      @traitfn function $(esc(FUN))(x1::::IsEltypeSuperOfMissing, x...; kwargs...)
        $(esc(FUN))(x1, PassMissing(), x...; kwargs...)
      end
    end
  else
    defaultmissingmethod = :()
  end
  quote
$defaultmissingmethod
@traitfn function $(esc(FUN))(x1::::!(IsEltypeSuperOfMissing), 
  ::MissingStrategy, x...; kwargs...)
    # call the original function without missing strategy
    $(esc(FUN))(x1, x...; kwargs...)
end
@traitfn function $(esc(FUN))(x1::::IsEltypeSuperOfMissing, 
  ::PassMissing, x...; kwargs...)
    any(ismissing.(x1)) && return(missing)
    x1nm = convert.(nonmissingtype(eltype(x1)),x1)
    Missing <: typeof(x1nm) && error("could not convert to nonmissing type")
    $(esc(FUN))(x1nm, x...; kwargs...)
end
@traitfn function $(esc(FUN))(x1::::IsEltypeSuperOfMissing, 
  ::HandleMissingStrategy, x...; kwargs...)
    x1nm = $x1nmskip
    Missing <: typeof(x1nm) && error("could not convert to nonmissing type")
    return($(esc(FUN))(x1nm, x...; kwargs...))
end
  end # quote
end