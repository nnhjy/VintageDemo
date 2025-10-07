# Sources

1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/)
2. [ONDP Study Explorer](https://www.entsoe.eu/outlooks/offshore-hub/tyndp-ondp)
3. [ONDP report on Northern Seas](https://eepublicdownloads.blob.core.windows.net/public-cdn-container/tyndp-documents/ONDP2024/web_entso-e_ONDP_NS_240226.pdf)

- North Sea scope 
    
    - lat: 50.5 ~ 62.0, NS lon: -3.7 ~ 8.6

    |	    |   OFFSHORE_NODE	| OFFSHORE_NODE_TYPE	| HOME_NODE	| LAT	    | LON
    | ----- | ---------------   | --------------------  | --------- | --------  | --------
    | 1     |	BEOH001	        | Hub	                | BE00	    | 51.4664	| 2.70605
    | 2     |	DEOH001	        | FarShoreHub	        | DE00	    | 54.8123	| 6.23643
    | 3     |	DKWOH01	        | FarShoreHub	        | DKW1	    | 56.1855	| 5.99119
    | 4     |	NLOH001	        | FarShoreHub	        | NL00	    | 54.126	| 3.93969
    | 5     |	NOSOH01	        | FarShoreHub	        | NOS0	    | 57.9005	| 3.917
    | 6     |	NOSOH02	        | Hub	                | NOS0	    | 60.9881	| 3.48128
    | 7     |	UKOH001	        | FarShoreHub	        | UK00	    | 54.8156	| 1.74205
    | 8     |	UKOH002	        | FarShoreHub	        | UK00	    | 57.818	| 0.970627
    | 9     |	UKOH003	        | Hub	                | UK00	    | 51.4269	| 0.936596
    | 10    |	UKOH006	        | Hub	                | UK00	    | 60.1129	| -1.52452


# Model Inputs

## Offshore wind profile

- folder: [OffshoreWindProfiles](.\OffshoreWindProfiles)
- source: 1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/) -> "ENTSO-E & ENTSOG TYNDP 2024 Scenarios  – Inputs" -> "Pan European Climatic Database (PECD) 3.1"
- NS nodes: select from [NODE.xlsx](.\OffshoreConfigNS\NODE.xlsx) based on lat and lon

## Offshore configuration

### Offshore wind techno-economic profile



### Transmission capacity and costs

- sheet `NS2shore` in [GRID.xlsx](.\OffshoreConfigNS\GRID.xlsx)
- source: 1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/) -> "ENTSO-E & ENTSOG TYNDP 2024 Scenarios  – Inputs" -> "Offshore Hub Modelling Inputs"
- original [GRID.xlsx](.\OffshoreConfigNS\GRID.xlsx) only contains the reference grids (2025, 2030, 2035, 2040, 2045, 2050),  capacity not explicitly given
- aggregated ONDP identified capacities are read from 2. [ONDP Study Explorer](https://www.entsoe.eu/outlooks/offshore-hub/tyndp-ondp) (2030, 2040, 2050), whereas the subcategories are missing
- special processing for the UK: according to `Section 6` of 3. [ONDP report on Northern Seas](https://eepublicdownloads.blob.core.windows.net/public-cdn-container/tyndp-documents/ONDP2024/web_entso-e_ONDP_NS_240226.pdf), connection to onshore UK from NS UK hubs only consists of the UKOH001. While direct links exist from BEOH and NLOH to onshore UK, the costs are *weirdly 0* and thus we ignore them as assuming they only serve inter-contry transmission.

- transmission capacity serves as the demand to be fulfilled by offshore wind generation

## Residue power supply (modelled as Energy Not Served, ENS)

- "ENTSO-E & ENTSOG TYNDP 2024 Scenarios  – Outputs" from 1. [TYNFP2024](https://2024.entsos-tyndp-scenarios.eu/download/)
- Climate Year 2009 for consistency from 2030-2050
