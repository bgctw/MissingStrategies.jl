"""
    @handlemissings(fun, collectskipped=false, definedefault=false)
    
Define several methods for function `fun` 
that handle missing values in the elements of its first argument.

The new methods dispatch on their first argument of
trait [`IsEltypeSuperOfMissing`](@ref). 
The second argument is of type [`MissingStrategy`](@ref).
- `@traitfun fun(x1::::IsEltypeSuperOfMissing, ::PassMissing, ...)` 
  returns missing if there is any missing element in x. 
  Otherwise, it converts the type of each element to the corresponding nonmissing type
  and calls the original function
- `@traitfun fun(x1::::IsEltypeSuperOfMissing, ::HandleMissingStrategy, ...)` 
  passes the first argument to `Missings.skipmissing` and optionally
  to `Base.collect`, before calling the original function.
- `@traitfun fun(x1::::!(IsEltypeSuperOfMissing), ::MissingStrategy, ...)` 
  calls the original function with unchanged `x1`. This allows passing both argument types,
  including and not including missings, to the method with a `MissingStrategy` argument.

# Default method without strategy?
By setting argument `definedefault=true` an additional method is defined:
- `@traitfun fun(x1::::IsEltypeSuperOfMissing, ...)` forwarding
  to the `fun(x1, PassMissing(), ...)` as a default for handling missings.
However, if the original method has no specific type attached, then this new
method is never called, but rather the original method is called.
Furthermore, this can create methods which may accidentally match non-missing arguments 
for which the original funciton threw an `MethodError` and may cause indefine 
loop and StackOverFlow. Hence, its recommended to only define the default method,
if the original method explicitly constrains its type to non-missing.

# Notes  
For extending or overwriting the defintitions created by `@handlemissings` the
[`IsEltypeSuperOfMissing`](@ref) trait is useful. 

Note, that supplying a generator to the first argument, 
does not work with `@handlemissing`, because `eltype(<generator>) == Any`. 
Use [`typediter`](@ref) to explicitly associate
an eltype, which may be a supertype of Missing.

# Examples
```jldoctest; output=false
# a function desinged with not caring for missings in xvec:
frealvec(xvec::AbstractVector{<:Real}) = xvec

@handlemissings(frealvec, true, true) # defines several new methods

# define specific subtype of HandleMissingStrategy explicitly 
using SimpleTraits
@traitfn function frealvec(x1::::IsEltypeSuperOfMissing, 
  ::ExactMissing, x...; kwargs...) 
  "return exact computation here"
end

frealvec([1,2]) # calls original method
xm = [1,2,missing]      # caused a MethodError on original frealvec
frealvec(xm, PassMissing()) === missing
frealvec(xm, SkipMissing()) == frealvec([1,2]) 
frealvec(xm) === missing     # default method forwarding to PassMissing() 
#frealvec(1)       # beware: formerly "MethodError" now results in an indefinite loop
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