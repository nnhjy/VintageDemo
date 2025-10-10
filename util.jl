function print_annual_total_prod(DB_conn::DuckDB.DB, years::Int...)
    for year in years
        println(year,"s")
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
end;