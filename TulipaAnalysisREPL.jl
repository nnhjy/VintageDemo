"""
Author: Huang, Jiangyi (Chair of Energy System Analysis, ETH Zurich)
Date: 2025-Sep-03

- Interactive workflow for analysing Tulipa.jl model instance and associated analysis codes
- Excute this script in REPL: "Shift"+"Enter"
"""

# To use the function `run_tulipa_workflow()`
include("./runTulipa.jl")

# specify absolute project environment folder
env_jl = @__DIR__
using Pkg; Pkg.activate(env_jl)

import TulipaIO as TIO
import TulipaEnergyModel as TEM
using DuckDB

# input folder should be placed at the same place as this script
input_dir_full = joinpath(@__DIR__, "Tulipa-multi-year-full/inputs-no-vintage-standard")
_output_dir = "./temp_output"

# output folder locates in the project jl_env folder
output_dir_full = jl_env * _output_dir
!isdir(output_dir_full) && mkdir(output_dir_full)

energy_problem = run_tulipa_workflow(
    input_dir_full, output_dir_full; 
    model_parameters_file = joinpath(input_dir_full, "model-parameters-example.toml"),
    model_file_name = joinpath(output_dir_full, "model.lp"),
    show_log=false,
)

