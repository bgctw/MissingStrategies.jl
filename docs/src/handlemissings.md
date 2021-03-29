# Default Handling of missing values 

Several functions and macros help to extend functions 
that were designed not taking care of missing values. 

## Main macros
The main tools are macros 
- `@handlemissings_stub`: defines only the dispatch infrastructure to be 
  extended manually
- `@handlemissings_typed`: additionally defines default handling for 
  `PassMissing` and `SkipMissing`
  for arguments whose eltye does not match missings
- `@handlemissings_any`: define these handling 
  for arguments whose eltype does match missings including `Any`.

```@docs
@handlemissings_stub
@handlemissings_typed
@handlemissings_any
```

## Infrastructure
The macros above just wrap a call to the `handlemissings` function using 
different argument values, especially different generator functions.

```@docs
handlemissings
```

The SimpleTraits package together with the [`IsEltypeSuperOfMissing`](@ref) trait 
is used to dispatch to
different methods depending on whether the eltype of a given argument allows
for missing or does not allow for missings.

The orginal method is extended by a method signature with modified the type of
a given argument, usually to eltype `Union{Missing,<eltype_orig>}` and an additional
argument `ms::MissingStrategy`. The new method forwards to a dispatching function
of name `<name_orig>_<suffix>` with MissingStrategy as the first argument and 
given argument `x` of type `x::::IsEltypeSuperOfMissing`. The suffix defaults to "_hm" 
but an be changed
to avoid method ambiguities if methods are extended that differ only by the original
type of `x`. A further advantage of using a separate dispatching method is, that 
the original function is not extended by too many new methods.

The dispatching function can be extended by `SimpleTraits.@traitfn` to handle
the differnt combinations of whether eltye of x was missing or not and the different
Missing strategies. See [`@handlemissings_stub`](@ref) for an example.


### Generator functions

The argument `gens` of [`handlemissings`](@ref) takes a tuple of generator functions, 
that do the actual work of defining additional methods.

The used generator functions are defined in submodule `mgen`
```@docs
mgen
mgen.forwarder()
mgen.missingstrategy_notsuperofeltype()
mgen.passmissing_nonconvert()
mgen.passmissing_convert()
mgen.handlemissing_collect_skip()
mgen.handlemissing_skip()
```

Each generator function requires arguments that are collected by
and passed by splatting the dictionary results in the call of a generator function.

```@docs
getdispatchinfo
```



