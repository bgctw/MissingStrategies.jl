# Strategies for dealing with missings 

The following types support methods to deal with presence of missing values
in their inputs.

```@docs
MissingStrategy
```

Usually, methods should return `missing` if there are
missings present in the input. This `PassMissing()` strategy ensures, 
that missing are not accidently bypassed unconsciously. 
Hence, `PassMissing()` is a good default value for the strategy.

If a caller knows that there might by missing values present, he can consciously
request to handle missings by supplying one of subtypes of `HandleMissingStrategy`.
For an explicit dealing with missings that may cause some cost in computation
use `ExactMissing`. For ignoring missing values use `SkipMissing`.

## Design choices
The design strategies alternatively could be passed by keyword arguments,
e.g. `skipmissing::Bool=true` or by an enum type.
Modelling the strategies by a type system allows the dispatch system and the 
compiler to work on them. 

This comes with several advantages:
- Avoid method matching ambiguities across existing methods that cannot
  handle missing values and their extensions by the same name and argument types aside
  from the MissingStrategy.
- Generate efficient code, because `if` branches can be pruned at compile time
- Extensible to further strategies
  
  
