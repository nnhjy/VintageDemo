# Initialising `julia` environment for project VintageDemo

# To run the script under the project dir ".../VintageDemo"
# Option 1. In terminal:
#=
    cd "path.to/Projects/VintageDemo"
    julia ./jl_env_setup.jl 
    julia ./jl_env_setup.jl --fix_version   # optional, to fix package versions as specified below
=#
# Option 2. In Julia REPL:
#=
    julia> cd("path.to/Projects/VintageDemo")
    julia> fix_version = true               # optional, to fix package versions as specified below
    julia> include("./jl_env_setup.jl")
=#

# Activate the Julia env at the project dir
using Pkg; Pkg.activate(@__DIR__)

_fix_version = (@isdefined fix_version) ? fix_version : false 
!isempty(ARGS) && ARGS[1] == "--fix_version" && (_fix_version = true)

# Optionally, fix package versions to ensure compatibility
_fix_version && begin
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

    println("adding supporting packages for in-depth analysis ...")
    Pkg.add("Plots")    # latest release version from regiestry
    Pkg.add("IJulia")    # latest release version from regiestry
    Pkg.add("JuMP")    # latest release version from regiestry
end

# install all required packages w.r.t. the Project.toml
Pkg.instantiate()   # will not downgrade or upgrade installed packages

# Build IJulia so that Julia cells in ipynb files can run
try
    Pkg.build("IJulia")
catch e
    println("IJulia build error: ", e)
    println("Reinstalling IJulia...")
    Pkg.add("IJulia")
    Pkg.build("IJulia")
end