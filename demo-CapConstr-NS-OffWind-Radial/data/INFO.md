# Sources

1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/)
2. [ONDP 2024 Study Explorer & Reports](https://www.entsoe.eu/outlooks/offshore-hub/tyndp-ondp)
    - [ONDP 2024 report on Northern Seas](https://eepublicdownloads.blob.core.windows.net/public-cdn-container/tyndp-documents/ONDP2024/web_entso-e_ONDP_NS_240226.pdf)
    - [ONDP 2024 methodology](https://eepublicdownloads.blob.core.windows.net/public-cdn-container/tyndp-documents/ONDP2024/ONDP2024-methodology.pdf)

# North Sea scope 

## North Sea offshore nodes

- source: `NODE.xlsx` at [ONDP Offshore Hub Modelling Inputs](https://2024-data.entsos-tyndp-scenarios.eu/files/scenarios-inputs/Offshore-hubs.zip)

- lat: 50.5 ~ 62.0, NS lon: -3.7 ~ 8.6
- ref: [IHO North Sea boundaries](http://marineregions.org/mrgid/2350) (CRS format: `EPSG:4326`)

- Offshore hub nodes

| No | OFFSHORE_NODE | OFFSHORE_NODE_TYPE | HOME_NODE | LAT          | LON          
|----|---------------|--------------------|-----------|--------------|--------------
| 1  | BEOH001       | Hub                | BE00      | 51.46641148  | 2.706047207  
| 2  | DEOH001       | FarShoreHub        | DE00      | 54.81229476  | 6.236432504  
| 3  | DKWOH01       | FarShoreHub        | DKW1      | 56.18549166  | 5.99118908   
| 4  | NLOH001       | FarShoreHub        | NL00      | 54.12600249  | 3.939687368    
| 5  | NOSOH01       | FarShoreHub        | NOS0      | 57.90052589  | 3.917004645  
| 6  | NOSOH02       | Hub                | NOS0      | 60.98813833  | 3.481279692  
| 7  | UKOH001       | FarShoreHub        | UK00      | 54.81560891  | 1.742048124  
| 8  | UKOH002       | FarShoreHub        | UK00      | 57.81804897  | 0.970627314  
| 9  | UKOH003       | Hub                | UK00      | 51.42690719  | 0.936596186  
| 10 | UKOH006       | Hub                | UK00      | 60.11287284  | -1.524519992 

- The following `Radial` node stands for near-shore-zone dedicated to offshore wind power supply exclusively to *HomeMarket* ([assumptions (P21)](https://2024.entsos-tyndp-scenarios.eu/wp-content/uploads/2023/07/20230704-Modelling_Methodologies__Draft_Assumptions.pptx), [methodology](https://eepublicdownloads.blob.core.windows.net/public-cdn-container/tyndp-documents/ONDP2024/ONDP2024-methodology.pdf)), having no connection capacity-cost specification.

| No | OFFSHORE_NODE | OFFSHORE_NODE_TYPE | HOME_NODE | LAT          | LON          
|----|---------------|--------------------|-----------|--------------|--------------
| 1  | DEOR001       | Radial             | DE00      | 54.24292067  | 8.239364068  
| 2  | NLOR001       | Radial             | NL00      | 52.93996669  | 4.47511208   
| 3  | NOSOR01       | Radial             | NOS0      | 58.55469094  | 7.222983677  

# Model Inputs

## Offshore wind profile

- file: [input_profiles_offshore_wind_no-vintage](.\input_profiles_offshore_wind_no-vintage.csv) and [input_profiles_offshore_wind_vintage](.\input_profiles_offshore_wind_vintage.csv)
- source: 1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/) -> "ENTSO-E & ENTSOG TYNDP 2024 Scenarios  – Inputs" -> "Pan European Climatic Database (PECD) 3.1"
- NS nodes: select from [input_GRID.xlsx](.\input_GRID.xlsx) based on lat and lon
- profile selection -> based on the capacity (planned & potential, see sheet `ZONE_POTENTIAL` in [input_GENERATOR.xlsx](.\input_GENERATOR.xlsx))
    - average of the selected countries per climate year
    - 2030: DE, UK, DK
    - 2040: DE, UK, DK, NL
    - 2050: DE, BE (the only two availables)

## Offshore configuration

### Offshore wind techno-economic profile

- file: [input_GENERATOR.xlsx](.\input_GENERATOR.xlsx)
- technology selection: DC_FB_OH

### Transmission capacity and costs

- file: [input_GRID.xlsx](.\input_GRID.xlsx) -> sheet `NS2shore`
- source: 1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/) -> "ENTSO-E & ENTSOG TYNDP 2024 Scenarios  – Inputs" -> "Offshore Hub Modelling Inputs"
- original [input_GRID.xlsx](.\input_GRID.xlsx) only contains the reference grids (2025, 2030, 2035, 2040, 2045, 2050), capacity not explicitly given
- aggregated ONDP identified capacities are read from 2. [ONDP Study Explorer](https://www.entsoe.eu/outlooks/offshore-hub/tyndp-ondp) (2030, 2040, 2050), whereas the subcategories are missing
- special processing for the UK: according to `Section 6` of 3. [ONDP report on Northern Seas](https://eepublicdownloads.blob.core.windows.net/public-cdn-container/tyndp-documents/ONDP2024/web_entso-e_ONDP_NS_240226.pdf), connection to onshore UK from NS UK hubs only consists of the UKOH001. While direct links exist from BEOH and NLOH to onshore UK, the costs are *weirdly 0* and thus we ignore them as assuming they only serve inter-contry transmission.

- Offshore transmission directly from `wind` to `demand<xx>`, which is equivalent to assuming a direct offshore wind supply to onshore markets, i.e. the radial offshore wind.
- transmission capacity makes no sense in this configuration: the data is for all wind production per country, whereas here the transmission (transport flow) capacity is for individual wind installations.
- transmission OPEX is modelled as the `operational_cost` for the flow from `wind` to `demand<xx>` in `flow-milestone.csv`.

## Onshore configuration

### Onshore electricity demand

- file: [input_demand_w_profiles.xlsx](.\input_demand_w_profiles.xlsx)
- source: [TYNDP2024 Demand Profiles](https://2024.entsos-tyndp-scenarios.eu/download/)
- demand with timeseries profile (`asset-milestone.csv`, `asset-profiles.csv`, `profiles-rep-periods.csv`)

### Residue power supply (modelled as Energy Not Served, ENS)

- file: [input_ENS_prices_CY2009.xlsx](.\input_ENS_prices_CY2009.xlsx)
- source: "ENTSO-E & ENTSOG TYNDP 2024 Scenarios  – Outputs" from 1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/)
- Choice of Climate Year CY2009 for consistency from 2030-2050
- 95 percentile of the marginal costs as the `operational_cost` for ens asset (`flow-milestone.csv`)
    - 2030: National Trend scenario (the only available)
    - 2040 & 2050: Distributed Energy scenario (more pessimistic than the Global Ambition scenario)

- ens capacity to cover all demands (`initial_units` in `asset-both.csv`)

# Other model setup

1. Discount rate = 3% [EUROCONTROL Standard Inputs for Economic Analyses](https://ansperformance.eu/economics/cba/standard-inputs/latest/chapters/discount_rate.html#:~:text=The%20discount%20rate%20is%20the%20annual%20rate%20used,%5B1%5D%20A%20nominal%20discount%20rate%20has%20three%20components%3A)
2. WACC for offshore wind = 2.5% [IRENA 2023](https://www.irena.org/Publications/2023/May/The-cost-of-financing-for-renewable-power), [IEA 2021](https://www.iea.org/reports/cost-of-capital-observatory/tools-and-analysis), 