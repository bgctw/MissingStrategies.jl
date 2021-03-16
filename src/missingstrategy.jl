"""
    MissingStrategy()

Suptertype of Abstract and Singleton Types that signify how a method should deal with
missing values
- └`PassMissing`: Singleton: return missing, if a missing value is encountered
- └`HandleMissingStrategy`: Abstract type: take missing values consciously into account
  - └`SkipMissing`: ignore missing values
  - └`ExactMissing`: unbiased processing 

See [`@handlemissings`](@ref) on how to extend functions by methods handling
these strategies.  
"""
abstract type MissingStrategy end,
struct PassMissing <: MissingStrategy end,
abstract type HandleMissingStrategy <: MissingStrategy end,
struct SkipMissing <: HandleMissingStrategy end,
struct ExactMissing <: HandleMissingStrategy end

