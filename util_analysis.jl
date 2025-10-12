using TulipaEnergyModel
using JuMP
using DuckDB
using DataFrames


# Calculate annual flows between assets that contain specific terms
# e.g., "wind" to "demand" or "ens" to "demand"
function annual_flows_between_assets(
    DB_conn::DuckDB.DB, from_asset_term::String, to_asset_term::String
)
    # Create DataFrame with sum per milestone year for wind-to-demand flows
    df_flow_data = filter(
        row -> occursin(from_asset_term, row.from_asset) && occursin(to_asset_term, row.to_asset),
        TIO.get_table(DB_conn, "var_flow")
    )

    df_flows_by_year = combine(
        groupby(df_flow_data, :year),
        :solution => sum => :annual_flow
    )

    # Convert to TWh and round
    df_flows_by_year.annual_flow_TWh = round.(df_flows_by_year.annual_flow / 1000, digits=2)

    # Create final DataFrame with desired columns
    df_flow_summary = DataFrame(
        milestone_year=df_flows_by_year.year,
        annual_flow=df_flows_by_year.annual_flow_TWh
    )

    return df_flow_summary
end

function print_annual_total_prod(DB_conn::DuckDB.DB, years::Int...)
    for year in years
        println(year, "s")
        filter(
            row -> row.milestone_year == year, 
            annual_flows_between_assets(DB_conn, "wind", "demand")
        ) |> row -> println("\t wind prodution: $(sum(row.annual_flow)) TWh p.a.")
        filter(
            row -> row.milestone_year == year, 
            annual_flows_between_assets(DB_conn, "ens", "demand")
        ) |> row -> println("\t market supply: $(sum(row.annual_flow)) TWh p.a.")
        # println(
        # "\t wind prodution: $(
        #     round(
        #         (filter(
        #             row -> occursin("wind", row.from_asset) && occursin("demand", row.to_asset) && row.year == year, 
        #             TIO.get_table(DB_conn, "var_flow")
        #         ).solution |> sum) / 1000, digits=2)
        #     ) TWh p.a."
        # )
    end
end

function objective_terms_value(
    TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, 
    DB_conn::DuckDB.DB
)
    system_investment_cost = _obj_investment_cost(TulipaProblemInstance, DB_conn)
    system_fixed_om_cost = sum([
        _obj_fixed_om_cost(TulipaProblemInstance, DB_conn, Val(:investment_method_compact)), 
        _obj_fixed_om_cost(TulipaProblemInstance, DB_conn, Val(:investment_method_simple))
    ])
    total_variable_om_cost = _obj_variable_om_cost(TulipaProblemInstance, DB_conn)
    return system_investment_cost, system_fixed_om_cost, total_variable_om_cost
end

function _obj_investment_cost(TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, DB_conn::DuckDB.DB)
    # investment cost calculation
    assets_investment = TulipaProblemInstance.variables[:assets_investment]
    indices = DuckDB.query(
        DB_conn,
        "SELECT
            var.id,
            t_objective_assets.weight_for_asset_investment_discount
                * t_objective_assets.investment_cost
                * t_objective_assets.capacity
                AS cost,
        FROM var_assets_investment AS var
        LEFT JOIN t_objective_assets
            ON var.asset = t_objective_assets.asset
            AND var.milestone_year = t_objective_assets.milestone_year
        ORDER BY
            var.id
        ",
    )
    
    system_investment_cost = @expression(
        TulipaProblemInstance.model,
        sum(
            row.cost * asset_investment for
            (row, asset_investment) in zip(indices, assets_investment.container)
        )
    )
    return JuMP.value(system_investment_cost)
end

function _obj_fixed_om_cost(
    TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, 
    DB_conn::DuckDB.DB, 
    ::Val{:investment_method_simple}
)
    expr_available_asset_units_simple_method = TulipaProblemInstance.expressions[:available_asset_units_simple_method]

    # Select expressions for simple method
    indices = DuckDB.query(
        DB_conn,
        "SELECT
            expr.id,
            t_objective_assets.weight_for_operation_discounts
                * asset_commission.fixed_cost
                * t_objective_assets.capacity
                AS cost,
        FROM expr_available_asset_units_simple_method AS expr
        LEFT JOIN asset_commission
            ON expr.asset = asset_commission.asset
            AND expr.commission_year = asset_commission.commission_year
        LEFT JOIN t_objective_assets
            ON expr.asset = t_objective_assets.asset
            AND expr.milestone_year = t_objective_assets.milestone_year
        ORDER BY
            expr.id
        ",
    )

    system_fixed_cost_simple_method = @expression(
        TulipaProblemInstance.model,
        sum(
            row.cost * expr_avail for (row, expr_avail) in
            zip(indices, expr_available_asset_units_simple_method.expressions[:assets])
        )
    )
    JuMP.value(system_fixed_cost_simple_method)
end

function _obj_fixed_om_cost(
    TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, 
    DB_conn::DuckDB.DB, 
    ::Val{:investment_method_compact}
)
    expr_available_asset_units_compact_method = TulipaProblemInstance.expressions[:available_asset_units_compact_method]
    
    # Select expressions for compact method
    indices = DuckDB.query(
        DB_conn,
        "SELECT
            expr.id,
            t_objective_assets.weight_for_operation_discounts
                * asset_commission.fixed_cost
                * t_objective_assets.capacity
                AS cost,
        FROM expr_available_asset_units_compact_method AS expr
        LEFT JOIN asset_commission
            ON expr.asset = asset_commission.asset
            AND expr.commission_year = asset_commission.commission_year
        LEFT JOIN t_objective_assets
            ON expr.asset = t_objective_assets.asset
            AND expr.milestone_year = t_objective_assets.milestone_year
        ORDER BY
            expr.id
        ",
    )
 
    system_fixed_cost_compact_method = @expression(
        TulipaProblemInstance.model,
        sum(
            row.cost * expr_avail for (row, expr_avail) in
            zip(indices, expr_available_asset_units_compact_method.expressions[:assets])
        )
    )
    JuMP.value(system_fixed_cost_compact_method)
end

function _obj_variable_om_cost(
    TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, 
    DB_conn::DuckDB.DB
)
    indices = DuckDB.query(
        DB_conn,
        "SELECT
            var.id,
            t_objective_flows.weight_for_operation_discounts
                * rpinfo.weight_sum
                * rpinfo.resolution
                * (var.time_block_end - var.time_block_start + 1)
                * t_objective_flows.variable_cost
                AS cost,
        FROM var_flow AS var
        LEFT JOIN t_objective_flows
            ON var.from_asset = t_objective_flows.from_asset
            AND var.to_asset = t_objective_flows.to_asset
            AND var.year = t_objective_flows.milestone_year
        LEFT JOIN (
            SELECT
                rpmap.year,
                rpmap.rep_period,
                SUM(weight) AS weight_sum,
                ANY_VALUE(rpdata.resolution) AS resolution
            FROM rep_periods_mapping AS rpmap
            LEFT JOIN rep_periods_data AS rpdata
                ON rpmap.year=rpdata.year AND rpmap.rep_period=rpdata.rep_period
            GROUP BY rpmap.year, rpmap.rep_period
        ) AS rpinfo
            ON var.year = rpinfo.year
            AND var.rep_period = rpinfo.rep_period
        LEFT JOIN asset
            ON asset.asset = var.from_asset
        WHERE asset.investment_method != 'semi-compact'
        ORDER BY var.id
        ",
    )
 
    # For the flows_operational_cost, we cannot use the zip method as done in all other terms,
    # because there are more flow variables than the number of rows in indices,
    # i.e., we only consider the costs of the flows that are not in semi-compact method
    var_flow = TulipaProblemInstance.variables[:flow].container
    flows_operational_cost = @expression(
        TulipaProblemInstance.model, sum(row.cost * var_flow[row.id] for row in indices)
    )
    return JuMP.value(flows_operational_cost)
end
