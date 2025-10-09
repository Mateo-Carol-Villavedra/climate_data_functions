# extract_and_compile_clim.data



##  Description. 

A function to process climate rasters from previous workflow steps, extracting climate data for every date at user-specified locations and converting it to a long-format dataframe. <br/>

The function takes raster files (annual NetCDF files from download functions) and a dataframe of grid cell centroids, then extracts daily climate values for each location and date combination. <br/>

For each grid cell centroid, the function extracts data for every day across all years in the provided rasters. If a centroid has data for `n` years, it will have approximately `n × 365` (or `366` for leap years) rows in the output - one row per day per location. <br/>

The function intelligently handles multiple climate variables from different sources (SILO, AGCD, ANUClimate), automatically detecting whether to use rescaled or original resolution files, and merging all variables into a single comprehensive dataframe. <br/>

**Important:** The function automatically prioritizes rescaled ANUClimate files (if present) over original resolution files to ensure compatibility when combining data sources. <br/>

The resulting long-format dataframe has each row representing a unique combination of location (grid cell) and date, with columns for all climate variables extracted. <br/>

<br/>

----


## Function Arguments and Input

### var_directories: <br/>
A character vector of file paths to climate variable directories to be processed. <br/>
Each directory should contain either a `processed` subdirectory (from download functions) or a `rescaled` subdirectory (from `rescale_rasters` function). <br/>
The function will automatically use rescaled files if available, otherwise uses processed files. <br/>

Example: `c("path_to_clim_data/daily_rain", "path_to_clim_data/max_temp", "path_to_clim_data/t_min", "path_to_clim_data/t_max")` <br/>
<br/>


### centroid_df: <br/>
A dataframe of grid cell centroids for which climate data should be extracted. <br/>
Typically the output of `make_cell_centroids_df` using `method = "grid"`. <br/>
Users can provide a custom dataframe, but it must adhere to the following requirements:

**Required columns:**

|Colname      |    Description            | Format |
|:------------|:--------------------------|:-------|
| lat         | Latitude of cell centroid | Decimal degrees, CRS:4326 |
| lon         | Longitude of cell centroid | Decimal degrees, CRS:4326 |
| centroid.id | Unique identifier for each location | Integer or character |

**CRITICAL:** Coordinates must be rounded to match the resolution of the rasters being used:
- If using AGCD/SILO/Rescaled ANUClimate: 0.05° × 0.05° resolution
- If using original resolution ANUClimate ONLY: 0.01° × 0.01° resolution

Example centroid_df structure:
```
      lat      lon    centroid.id
1  -35.00   150.40              1
2  -35.00   150.45              2
3  -35.00   150.50              3
4  -35.00   150.55              4
5  -35.00   150.60              5
```
<br/>


### output_filepath: <br/>
A file path specifying where to save the compiled climate dataframe as an RDS file. <br/>
Include the `.RDS` extension in the filename. <br/>

Example: `"path_to_save_location/compiled_climate_data.RDS"` <br/>
<br/>


### check_crs: <br/>
A logical value determining whether to check CRS compatibility across files and issue warnings. <br/>
Default: `TRUE` <br/>

If `TRUE`, the function verifies that all files for each variable have consistent coordinate reference systems and warns if discrepancies are detected. <br/>
<br/>

----


## Output

Returns and saves a long-format data.table/dataframe where each row represents a unique combination of location (grid cell) and date. <br/>

**Output structure:**

|Column Name    | Description |
|:--------------|:------------|
| lat           | Latitude of grid cell centroid |
| lon           | Longitude of grid cell centroid |
| centroid.id   | Unique identifier for grid cell |
| id            | Combined identifier: `centroid.id_year` |
| clim_date     | Date of climate observation (Date object) |
| clim_year     | Year extracted from date |
| clim_month    | Month extracted from date |
| clim_m.day    | Day of month |
| clim_day.month| Day.Month format (e.g., "15.3" for March 15) |
| [variable_1]  | Climate values for variable 1 |
| [variable_2]  | Climate values for variable 2 |
| ...           | Additional climate variables |

**Number of rows:** `number_of_centroids × total_days_in_all_years` <br/>

For example, if you have:
- 100 centroids
- 3 years of data (2018-2020, including one leap year)
- Total days = 365 + 366 + 365 = 1096 days

The output will have: 100 × 1096 = 109,600 rows <br/>

The dataframe is saved as an RDS file at the specified output path and returned to the user. <br/>

<br/>

----


## Notes:

- **Resolution matching is critical:** Centroid coordinates must be rounded to match raster resolution to ensure accurate data extraction
- The function automatically detects and uses rescaled ANUClimate files (if present) to maintain resolution consistency across data sources
- If using only ANUClimate data at original resolution (0.01° × 0.01°), do not rescale and ensure centroids match this resolution
- The function performs CRS transformations automatically if centroids and rasters have different projections
- All variables are merged on location (lat, lon, centroid.id) and date (clim_date), ensuring aligned records
- The function validates that all variables have the same number of unique join keys before merging to prevent row duplication
- Progress messages indicate which files are being processed and whether rescaled or original files are used
- **Shapefile margin warning:** If NA values appear in the output, the shapefile used to crop rasters in earlier steps may have been too small, excluding cells that align with centroids. Ensure the crop shapefile encompasses a margin of several cells beyond your area of interest
- Memory management: The function uses `data.table` for efficient processing and includes garbage collection steps to manage memory with large datasets
- The function handles leap years automatically, ensuring correct date attribution for all days
- CRS checking can identify inconsistencies between files but does not prevent processing


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/extract_and_compile_clim.data.R")
```

<br/>

Load the grid centroids dataframe produced by `make_cell_centroids_df`:
```
grid_centroids <- read.csv("path_to_centroids/region.grid_centroids_res=0.05.csv")
```

<br/>

Extract and compile climate data from multiple sources (SILO and ANUClimate):
```
climate_vars <- c("path_to_clim_data/daily_rain",
                  "path_to_clim_data/radiation", 
                  "path_to_clim_data/max_temp",
                  "path_to_clim_data/min_temp",
                  "path_to_clim_data/t_min",
                  "path_to_clim_data/t_max")

compiled_climate_df <- extract_and_compile_clim.data(
                           var_directories = climate_vars,
                           centroid_df = grid_centroids,
                           output_filepath = "path_to_save_location/compiled_climate_data.RDS",
                           check_crs = TRUE)
```

<br/>

Extract data from AGCD variables only:
```
climate_vars <- c("path_to_clim_data/precip",
                  "path_to_clim_data/tmax",
                  "path_to_clim_data/tmin")

compiled_climate_df <- extract_and_compile_clim.data(
                           var_directories = climate_vars,
                           centroid_df = grid_centroids,
                           output_filepath = "path_to_save_location/AGCD_compiled_data.RDS",
                           check_crs = TRUE)
```

<br/>

Process without CRS checking (faster, but less diagnostic information):
```
compiled_climate_df <- extract_and_compile_clim.data(
                           var_directories = climate_vars,
                           centroid_df = grid_centroids,
                           output_filepath = "path_to_save_location/compiled_climate_data.RDS",
                           check_crs = FALSE)
```

<br/>

Load and inspect the compiled data:
```
# Load the saved RDS file
climate_data <- readRDS("path_to_save_location/compiled_climate_data.RDS")

# Check structure
str(climate_data)

# View first few rows
head(climate_data)

# Check for NA values
summary(climate_data)

# Verify number of records per location
table(table(climate_data$centroid.id))
```





<br/>

----


<br/>
