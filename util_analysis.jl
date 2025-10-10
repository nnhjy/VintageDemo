using TulipaEnergyModel
using JuMP
using DuckDB

function print_annual_total_prod(DB_conn::DuckDB.DB, years::Int...)
    for year in years
        println(year, "s")
        println(
        "\t wind prodution: $(
            round(
                (filter(
                    row -> occursin("wind", row.from_asset) && occursin("demand", row.to_asset) && row.year == year, 
                    TIO.get_table(DB_conn, "var_flow")
                ).solution |> sum) / 1000, digits=2)
            ) TWh p.a.",
        "\t market supply: $(
            round(
                (filter(
                    row -> occursin("ens", row.from_asset) && occursin("demand", row.to_asset) && row.year == year, 
                    TIO.get_table(DB_conn, "var_flow")
                ).solution |> sum) / 1000 , digits=2) 
            ) TWh p.a."
        )
    end
end

function objective_terms_value(
    TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, 
    DB_conn::DuckDB.DB
)
    system_investment_cost = _obj_investment_cost(TulipaProblemInstance, DB_conn)
    system_fixed_om_cost = 
        + _obj_fixed_om_cost(TulipaProblemInstance, DB_conn, Val(:investment_method_compact)) 
        + _obj_fixed_om_cost(TulipaProblemInstance, DB_conn, Val(:investment_method_simple))
    total_variable_om_cost = _obj_flows_operational_cost(TulipaProblemInstance, DB_conn)
    return system_investment_cost, system_fixed_om_cost, total_variable_om_cost
end

function _obj_investment_cost(TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, DB_conn::DuckDB.DB)
    # investment cost calculation
    assets_investment = TulipaProblemInstance.variables[:assets_investment]
    indices = DuckDB.query(
        DB_conn,
        "SELECT
            var.id,
            obj.weight_for_asset_investment_discount
                * obj.investment_cost
                * obj.capacity
                AS cost,
        FROM var_assets_investment AS var
        LEFT JOIN t_objective_assets as obj
            ON var.asset = obj.asset
            AND var.milestone_year = obj.milestone_year
        ORDER BY var.id
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
            obj.weight_for_operation_discounts
                * asset_commission.fixed_cost
                * obj.capacity
                AS cost,
        FROM expr_available_asset_units_simple_method AS expr
        LEFT JOIN asset_commission
            ON expr.asset = asset_commission.asset
            AND expr.commission_year = asset_commission.commission_year
        LEFT JOIN t_objective_assets as obj
            ON expr.asset = obj.asset
            AND expr.milestone_year = obj.milestone_year
        ORDER BY expr.id
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
            obj.weight_for_operation_discounts
                * asset_commission.fixed_cost
                * obj.capacity
                AS cost,
        FROM expr_available_asset_units_compact_method AS expr
        LEFT JOIN asset_commission
            ON expr.asset = asset_commission.asset
            AND expr.commission_year = asset_commission.commission_year
        LEFT JOIN t_objective_assets as obj
            ON expr.asset = obj.asset
            AND expr.milestone_year = obj.milestone_year
        ORDER BY expr.id
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

function _obj_flows_operational_cost(
    TulipaProblemInstance::TulipaEnergyModel.EnergyProblem, 
    DB_conn::DuckDB.DB
)
    indices = DuckDB.query(
        DB_conn,
        "WITH rp_weight AS (
            SELECT
                year,
                rep_period,
                SUM(weight) AS weight_sum
            FROM rep_periods_mapping
            GROUP BY year, rep_period
        ),
        rp_res AS (
            SELECT
                year,
                rep_period,
                ANY_VALUE(resolution) AS resolution
            FROM rep_periods_data
            GROUP BY year, rep_period
        )
        SELECT
            var.id,
            obj.weight_for_operation_discounts
                * rp_weight.weight_sum
                * rp_res.resolution
                * (var.time_block_end - var.time_block_start + 1)
                * obj.variable_cost
                AS cost,
        FROM var_flow AS var
        LEFT JOIN t_objective_flows as obj
            ON var.from_asset = obj.from_asset
            AND var.to_asset = obj.to_asset
            AND var.year = obj.milestone_year
        LEFT JOIN rp_weight
            ON var.year = rp_weight.year
            AND var.rep_period = rp_weight.rep_period
        LEFT JOIN rp_res
            ON var.year = rp_res.year
            AND var.rep_period = rp_res.rep_period
        LEFT JOIN asset
            ON asset.asset = var.from_asset
        WHERE asset.investment_method != 'semi-compact'
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
