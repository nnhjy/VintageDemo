function calculate_wind_to_demand_flows(connection)
    # Create DataFrame with sum per milestone year for wind-to-demand flows
    wind_to_demand_flows = filter(
        row -> occursin("wind", row.from_asset) && occursin("demand", row.to_asset),
        TIO.get_table(connection, "var_flow")
    )
 
    wind_flows_by_year = combine(
        groupby(wind_to_demand_flows, :year),
        :solution => sum => :total_flow
    )
 
    # Convert to GW and round
    wind_flows_by_year.total_flow_GW = round.(wind_flows_by_year.total_flow / 1000, digits=2)
 
    # Create final DataFrame with desired columns
    wind_summary = DataFrame(
        milestone_year=wind_flows_by_year.year,
        sum_flow=wind_flows_by_year.total_flow_GW
    )
 
    return wind_summary
end
 
 
wind_to_demand_no_vintage = calculate_wind_to_demand_flows(connection_no_vintage)
wind_to_demand_vintage_standard = calculate_wind_to_demand_flows(connection_vintage_standard)
wind_to_demand_vintage_compact = calculate_wind_to_demand_flows(connection_vintage_compact)
 
 
function calculate_ens_to_demand_flows(connection)
    # Create DataFrame with sum per milestone year for ENS-to-demand flows
    ens_to_demand_flows = filter(
        row -> occursin("ens", row.from_asset) && occursin("demand", row.to_asset),
        TIO.get_table(connection, "var_flow")
    )
 
    ens_flows_by_year = combine(
        groupby(ens_to_demand_flows, :year),
        :solution => sum => :total_flow
    )
 
    # Convert to GW and round
    ens_flows_by_year.total_flow_GW = round.(ens_flows_by_year.total_flow / 1000, digits=2)
 
    # Create final DataFrame with desired columns
    ens_summary = DataFrame(
        milestone_year=ens_flows_by_year.year,
        sum_flow=ens_flows_by_year.total_flow_GW
    )
 
    return ens_summary
end
 
 
ens_to_demand_no_vintage = calculate_ens_to_demand_flows(connection_no_vintage)
ens_to_demand_vintage_standard = calculate_ens_to_demand_flows(connection_vintage_standard)
ens_to_demand_vintage_compact = calculate_ens_to_demand_flows(connection_vintage_compact)
 
 
plot(wind_to_demand_no_vintage.milestone_year, wind_to_demand_no_vintage.sum_flow,
    label="No vintage - wind to demand",
    xlabel="Milestone year",
    ylabel="Flow (GW)",
    seriestype=:scatter,
    markersize=6,
    markershape=:circle,
    color=:blue,
    xticks=minimum(wind_to_demand_no_vintage.milestone_year):10:maximum(wind_to_demand_no_vintage.milestone_year))
plot!(wind_to_demand_vintage_standard.milestone_year, wind_to_demand_vintage_standard.sum_flow,
    label="Vintage standard - wind to demand",
    seriestype=:scatter,
    markersize=6,
    markershape=:square,
    color=:green)
plot!(wind_to_demand_vintage_compact.milestone_year, wind_to_demand_vintage_compact.sum_flow,
    label="Vintage compact - wind to demand",
    seriestype=:scatter,
    markersize=6,
    markershape=:diamond,
    color=:red)
 
plot!(ens_to_demand_no_vintage.milestone_year, ens_to_demand_no_vintage.sum_flow,
    label="No vintage - ENS to demand",
    seriestype=:scatter,
    markersize=6,
    markershape=:utriangle,
    color=:lightblue)
plot!(ens_to_demand_vintage_standard.milestone_year, ens_to_demand_vintage_standard.sum_flow,
    label="Vintage standard - ENS to demand",
    seriestype=:scatter,
    markersize=6,
    markershape=:star5,
    color=:lightgreen)
plot!(ens_to_demand_vintage_compact.milestone_year, ens_to_demand_vintage_compact.sum_flow,
    label="Vintage compact - ENS to demand",
    seriestype=:scatter,
    markersize=6,
    markershape=:cross,
    color=:orange)
# savefig("wind_ens_to_demand_comparison.png")