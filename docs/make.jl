using Documenter
using MissingStrategies, Distributions, StatsBase, StatsPlots

push!(LOAD_PATH,"../src/")
# need to add Statistics and Distributions to Project.toml in docs/
#DocMeta.setdocmeta!(MissingStrategies, :DocTestSetup, :(using Statistics,Distributions,MissingStrategies); recursive=true)
#DocMeta.setdocmeta!(Distributions, :DocTestSetup, :(using Statistics,Distributions,MissingStrategies); recursive=true)
makedocs(sitename="MissingStrategies.jl",
         doctest  = false, 
         pages = [
            "Home" => "index.md",
            "Types" => "missingstrategy.md",
            "Dispatch" => "iseltypesuperofmissing.md",
            "Default" => "handlemissings.md",
            "TypedIteraotr" => "typediter.md",
         ],
         modules = [MissingStrategies],
         format = Documenter.HTML(prettyurls = false)
)
# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/bgctw/MissingStrategies.jl.git",
    devbranch = "main"
)
