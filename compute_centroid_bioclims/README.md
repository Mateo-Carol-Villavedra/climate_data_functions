# compute_centroid_bioclims



##  Description. 

A function to compute bioclimatic indices (BIO1-BIO27) for each grid cell centroid based on their assigned climate data from the `extract_and_compile_clim.data` function. <br/>

This function calculates bioclimatic indices for each calendar year at each grid cell location, using daily climate values for maximum temperature, minimum temperature, precipitation, and/or radiation. <br/>

Unlike `compute_ind_bioclims` which computes indices for individual samples with user specified periods, this function computes indices for every grid cell across all calendar years in a user defined time series (`period_start` & `period_end`), making it suitable for creating spatial grids of bioclimatic indices. <br/>

The function includes an optional temporal averaging capability, allowing users to compute multi-year average indices (e.g., decadal averages) for each grid cell (`av_period_by`). <br/>

Users can select which indices to compute and which climate variables to use, combining variables from any combination of the three databases (SILO, AGCD, ANUClimate). The function handles synonymous variable names (e.g., `tmax`, `max_temp`, `t_max` all represent maximum temperature). <br/>

The function will only fail if specific climate variables required for the requested indices are missing. Not all 4 climate variable types are needed unless computing all 27 indices. <br/>

Results are saved as an RDS file containing a dataframe with bioclimatic indices for each centroid and year (or averaged time period). <br/>

<br/>

----


## Function Arguments and Input

### centroid_clim.data: <br/>
The dataframe produced by the `extract_and_compile_clim.data` function containing climate data for all grid cell centroids across multiple years. <br/>

Must contain:
- `centroid.id` - unique centroid identifier
- `clim_date` - date of climate observation
- `clim_year` - year of climate observation
- `lat`, `lon` - location coordinates
- Climate variable columns (e.g., `tmax`, `tmin`, `precip`, `radiation`, etc.)

<br/>


### bioclim_indices: <br/>
A numeric vector specifying which bioclimatic indices to compute. <br/>
Values range from 1 to 27. <br/>


Example: `c(1, 2, 3, 4, 5, 6, 7, 8, 15, 22, 21, 26)` <br/>

**Variable requirements for each index:**

|Index | Category  |Required Variables | Description |
|:-----|:----------|:-------------------|:------------|
|BIO1  | Temperature | Max Temp, Min Temp | Annual Mean Temperature |
|BIO2  | Temperature | Max Temp, Min Temp | Mean Diurnal Range |
|BIO3  | Temperature | Max Temp, Min Temp | Isothermality |
|BIO4  | Temperature | Max Temp, Min Temp | Temperature Seasonality |
|BIO5  | Temperature | Max Temp | Max Temperature of Warmest Month |
|BIO6  | Temperature | Min Temp | Min Temperature of Coldest Month |
|BIO7  | Temperature | Max Temp, Min Temp | Temperature Annual Range |
|BIO8  | Temperature | Max Temp, Min Temp, Precip | Mean Temperature of Wettest Quarter |
|BIO9  | Temperature | Max Temp, Min Temp, Precip | Mean Temperature of Driest Quarter |
|BIO10 | Temperature | Max Temp | Mean Temperature of Warmest Quarter |
|BIO11 | Temperature | Min Temp | Mean Temperature of Coldest Quarter |
|BIO12 | Precipitation | Precip | Annual Precipitation |
|BIO13 | Precipitation | Precip | Precipitation of Wettest Month |
|BIO14 | Precipitation | Precip | Precipitation of Driest Month |
|BIO15 | Precipitation | Precip | Precipitation Seasonality |
|BIO16 | Precipitation | Precip | Precipitation of Wettest Quarter |
|BIO17 | Precipitation | Precip | Precipitation of Driest Quarter |
|BIO18 | Precipitation | Precip, Max Temp | Precipitation of Warmest Quarter |
|BIO19 | Precipitation | Precip, Min Temp | Precipitation of Coldest Quarter |
|BIO20 | Radiation | Radiation | Mean Annual Radiation |
|BIO21 | Radiation | Radiation | Highest Monthly Mean Radiation |
|BIO22 | Radiation | Radiation | Lowest Monthly Mean Radiation |
|BIO23 | Radiation | Radiation | Radiation Seasonality |
|BIO24 | Radiation | Radiation, Precip | Radiation of Wettest Quarter |
|BIO25 | Radiation |  Radiation, Precip | Radiation of Driest Quarter |
|BIO26 | Radiation |  Radiation, Max Temp | Radiation of Warmest Quarter |
|BIO27 | Radiation |  Radiation, Min Temp | Radiation of Coldest Quarter |

<br/>


### var.names: <br/>
A character vector specifying which climate variables to use for computing bioclimatic indices. <br/>

The function handles synonymous variable names from different data sources:

|Climate Variable     | AGCD Name   | SILO Name     | ANUClimate Name |
|:--------------------|:------------|:--------------|:----------------|
|Maximum Temperature  | `tmax`      | `max_temp`    | `t_max `        |
|Minimum Temperature  | `tmin`      | `min_temp`    | `t_min`         |
|Precipitation        | `precip`    | `daily_rain`  | `rain`          |
|Radiation            |             | `radiation`   | `srad`          |

**Important:** Only specify **one** variable name per climate type. For example, use either `"tmax"` OR `"max_temp"` OR `"t_max"`, but not multiple. The function will return an error if multiple synonymous variables are specified. <br/>

Example: `c("tmax", "tmin", "precip", "radiation")` <br/>
Example: `c("max_temp", "min_temp", "daily_rain", "radiation")` <br/>
Example: `c("t_max", "t_min", "rain", "srad")` <br/>
<br/>


### period_start: <br/>
A numeric value (year) specifying the first year of the temporal range to include in the analysis. <br/>
Used in conjunction with `period_end` and `av_period_by` to define averaging periods. <br/>

Example: `1990` <br/>
<br/>


### period_end: <br/>
A numeric value (year) specifying the last year of the temporal range to include in the analysis. <br/>
Used in conjunction with `period_start` and `av_period_by` to define averaging periods. <br/>

Example: `2020` <br/>
<br/>


### av_period_by: <br/>
A numeric value specifying how many years should be averaged together for each output record. <br/>

- `av_period_by = 1` - No averaging; bioclimatic indices computed for each individual year
- `av_period_by = 5` - 5-year averages (e.g., 1990-1994, 1995-1999, 2000-2004)
- `av_period_by = 10` - Decadal averages (e.g., 1990-1999, 2000-2009, 2010-2019)
- `av_period_by = 30` - 30-year climate normals

**Note:** Indices are calculated for each individual year first, then averaged across the specified periods. <br/>

Example: `10` for decadal averages <br/>
<br/>


### output_directory: <br/>
A file path specifying where to save the computed bioclimatic indices as an RDS file. <br/>
Include the `.RDS` extension in the filename. <br/>

Example: `"path_to_save_location/centroid_bioclim_indices.RDS"` <br/>
<br/>

----


## Output

Returns and saves a dataframe with bioclimatic indices for each grid cell centroid. <br/>

**Output structure (when av_period_by = 1):**

|Column Name  | Description |
|:------------|:------------|
| centroid.id | Unique grid cell identifier |
| clim_year   | Year for which indices were calculated |
| bio1        | BIO1 value (if requested) |
| bio2        | BIO2 value (if requested) |
| ...         | Additional requested indices |
| bioN        | BION value (if requested) |

**Output structure (when av_period_by > 1):**

|Column Name  | Description |
|:------------|:------------|
| centroid.id | Unique grid cell identifier |
| period      | Starting year of averaging period |
| bio1        | Averaged BIO1 value (if requested) |
| bio2        | Averaged BIO2 value (if requested) |
| ...         | Additional requested indices |
| bioN        | Averaged BION value (if requested) |

Only the indices specified in `bioclim_indices` will be included as columns. <br/>

The dataframe can be joined with centroid coordinates (from `make_cell_centroids_df`) to create spatial raster grids of bioclimatic indices. <br/>

The dataframe is saved as an RDS file at the specified output path and returned to the user. <br/>

<br/>

----


## Notes:

- The temporal averaging feature (`av_period_by`) is useful for creating climate normal periods or reducing inter-annual variability  <br/>
- The function automatically handles synonymous variable names from different data sources (SILO, AGCD, ANUClimate)
- If multiple synonymous variables exist in the input data (e.g., both `tmax` and `max_temp`), specify only one in `var.names` - the function will remove the others and standardize naming
- Not all four variable types (max temp, min temp, precip, radiation) are required unless computing all 27 indices
- The function validates that required variables are present for requested indices before processing
- Quarterly calculations use rolling 3-month periods (e.g., Jan-Feb-Mar, Feb-Mar-Apr, ..., Dec-Jan-Feb)
- Temperature seasonality (BIO4) is calculated using Kelvin to maintain standardization with Xu and Hutchinson (2011)
- Leap years (366 days) are handled automatically
- Processing time depends on the number of centroids, years, indices requested, and variables included
- For large datasets, consider processing subsets of years or indices separately
- The output can be converted back to raster format using the `terra` package for spatial visualization and analysis

<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/compute_centroid_bioclims.R")
```

<br/>

Load the compiled climate data produced by `extract_and_compile_clim.data`:
```
centroid_climate_data <- readRDS("path_to_data/compiled_climate_data.RDS")
```

<br/>

Compute annual bioclimatic indices for each centroid (no averaging):
```
centroid_bioclims <- compute_centroid_bioclims(
                         centroid_clim.data = centroid_climate_data,
                         bioclim_indices = c(1, 2, 5, 6, 12, 13, 20, 21),
                         var.names = c("tmax", "tmin", "precip", "radiation"),
                         period_start = 2010,
                         period_end = 2020,
                         av_period_by = 1,
                         output_directory = "path_to_save_location/annual_centroid_bioclims.RDS")
```

<br/>

Compute decadal average bioclimatic indices:
```
centroid_bioclims_decadal <- compute_centroid_bioclims(
                                 centroid_clim.data = centroid_climate_data,
                                 bioclim_indices = c(1:19),
                                 var.names = c("max_temp", "min_temp", "daily_rain"),
                                 period_start = 1990,
                                 period_end = 2020,
                                 av_period_by = 10,
                                 output_directory = "path_to_save_location/decadal_centroid_bioclims.RDS")
```

<br/>

Compute 30-year climate normals for temperature indices only:
```
climate_normals <- compute_centroid_bioclims(
                       centroid_clim.data = centroid_climate_data,
                       bioclim_indices = c(1, 2, 3, 4, 5, 6, 7, 10, 11),
                       var.names = c("tmax", "tmin"),
                       period_start = 1991,
                       period_end = 2020,
                       av_period_by = 30,
                       output_directory = "path_to_save_location/climate_normals_1991_2020.RDS")
```

<br/>

Compute 5-year averages for all 27 indices using mixed data sources:
```
centroid_bioclims_5yr <- compute_centroid_bioclims(
                             centroid_clim.data = centroid_climate_data,
                             bioclim_indices = c(1:27),
                             var.names = c("max_temp", "min_temp", "daily_rain", "srad"),
                             period_start = 2000,
                             period_end = 2020,
                             av_period_by = 5,
                             output_directory = "path_to_save_location/5yr_avg_all_indices.RDS")
```

<br/>

Compute radiation indices only with annual resolution:
```
radiation_indices <- compute_centroid_bioclims(
                         centroid_clim.data = centroid_climate_data,
                         bioclim_indices = c(20, 21, 22, 23),
                         var.names = c("radiation"),
                         period_start = 2015,
                         period_end = 2020,
                         av_period_by = 1,
                         output_directory = "path_to_save_location/radiation_indices_annual.RDS")
```

<br/>

Load computed indices and prepare for spatial visualization:
```
# Load the saved RDS file
bioclim_data <- readRDS("path_to_save_location/decadal_centroid_bioclims.RDS")

# Load centroid coordinates
centroids <- read.csv("path_to_centroids/region.grid_centroids_res=0.05.csv")

# Merge bioclim data with coordinates
spatial_bioclim <- merge(centroids, bioclim_data, by = "centroid.id")

# View structure
str(spatial_bioclim)

# Check for missing values
colSums(is.na(spatial_bioclim))

# Convert to raster for a specific period and index (example: BIO1 for 2010-2019)
library(terra)

bio1_2010s <- spatial_bioclim %>%
    filter(period == 2010) %>%
    select(lon, lat, bio1)

# Create raster
bio1_raster <- rast(bio1_2010s, type="xyz", crs="EPSG:4326")
plot(bio1_raster, main="BIO1: Annual Mean Temperature (2010-2019)")
```





<br/>

----


<br/>
