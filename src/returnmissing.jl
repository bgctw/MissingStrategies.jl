"""
    @returnmissing(expr)

Return `missing`, if `expr` evaluates to `missing`.    

# Example
```jldoctest; output=false
finner(x::Real) = x*2
f1(x) = finner(x)
f2(x) = finner(@returnmissing(x))
f1(3) == f2(3) == 2*3
# error: f1(missing)
ismissing(f2(missing))
# output
true
```
"""
macro returnmissing(expr)
    sym = gensym()
    quote
        $(sym) = $(esc(expr))
        ismissing($sym) && return missing
        $(sym) 
    end
end
