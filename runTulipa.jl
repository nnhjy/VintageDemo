# To run the script under the project dir ".../VintageDemo"
# Option 1. In terminal:
#=
    "path.to/Projects/VintageDemo"
    julia ./RunTulipaScenario.jl
=#
# Option 2. In Julia REPL:
#=
    julia> cd("path/to/VintageDemo")
    julia> include("./RunTulipaScenario.jl")
=#

function run_tulipa_workflow(_dir_in::String, _dir_out::String; kwargs...)
    _connection = DBInterface.connect(DuckDB.DB)
    TIO.read_csv_folder(_connection, _dir_in)
    TEM.populate_with_defaults!(_connection)

    return TEM.run_scenario(_connection; output_folder=_dir_out, kwargs...)
end

if abspath(PROGRAM_FILE) == @__FILE__
    # set the working directory with Julia environment
    jl_env = ENV["HOME"]*"/Projects/VintageDemo/"
    using Pkg; Pkg.activate(jl_env)

    import TulipaIO as TIO
    import TulipaEnergyModel as TEM
    using DuckDB

    # input folder should be placed at the same place as this script
    input_dir_full = joinpath(@__DIR__, "Tulipa-multi-year-full/inputs-no-vintage-standard")
    _output_dir = "./temp_output"

    # output folder locates in the project jl_env folder
    output_dir_full = jl_env * _output_dir
    !isdir(output_dir_full) && mkdir(output_dir_full);

    energy_problem = run_tulipa_workflow(
        input_dir_full, output_dir_full; 
        model_parameters_file = joinpath(input_dir_full, "model-parameters-example.toml"),
        model_file_name = joinpath(output_dir_full, "model.lp"),
        show_log=false,
    )
end
