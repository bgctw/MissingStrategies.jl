using Documenter
using MissingStrategies

push!(LOAD_PATH,"../src/")
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
