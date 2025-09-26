# Initialising `julia` environment for project VintageDemo

# To run the script under the project dir ".../VintageDemo"
# Option 1. In terminal:
#=
    cd "path.to/Projects/VintageDemo"
    julia ./setup_julia_env.jl
=#
# Option 2. In Julia REPL:
#=
    julia> cd("path.to/Projects/VintageDemo")
    julia> include("./setup_julia_env.jl")
=#

# Activate the Julia env at the project dir
using Pkg; Pkg.activate(@__DIR__)

if !isempty(ARGS) & ARGS[1] == "--new"
    println("adding core Tulipa packages ...")
    Pkg.add(name="TulipaEnergyModel", version="0.17.1")   # exact version
    Pkg.add(name="TulipaIO", version="0.5")    # latest in the 0.5.x series
    
    println("adding core supporting packages for Tulipa ...")
    Pkg.add("DuckDB")    # latest release from regiestry
    Pkg.add("DataFrames")    # latest release version from regiestry
    Pkg.add("HiGHS")    # latest release version from regiestry
    
    println("adding Tulipa ancillary packages ...")
    Pkg.add(name="TulipaClustering", version="0.4") # latest in the 0.4.x series
    Pkg.add("Distances")    # latest release version from regiestry

    println("adding general supporting packages ...")
    Pkg.add("Plots")    # latest release version from regiestry
    Pkg.add("IJulia")    # latest release version from regiestry
end

# install all required packages in this project
Pkg.instantiate()

# Build IJulia so that Julia cells in ipynb files can run
try
    Pkg.build("IJulia")
catch e
    println("IJulia build error: ", e)
    println("Reinstalling IJulia...")
    Pkg.add("IJulia")
    Pkg.build("IJulia")
end