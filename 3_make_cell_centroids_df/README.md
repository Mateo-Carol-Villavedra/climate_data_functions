# make_cell_centroids_df



##  Description. 

A function to produce dataframes of grid cell centroid coordinates for a cropped region, which are used in downstream workflow steps. <br/>

This function serves two distinct purposes depending on the selected method:

1. **Grid Method (`method = "grid"`):** Computes centroid locations for **all grid cells** in the raster extent. This output is used by `extract_and_compile_clim.data` to extract climate data for every location in the study region.

2. **Sample Method (`method = "sample"`):** Computes centroid coordinates for **individual samples** by rounding raw latitude and longitude coordinates to match the raster resolution. This ensures each sample is assigned to the appropriate grid cell. This output is used by `assign_clim.data` to assign climate data to individual samples.

The function automatically determines the appropriate resolution from a template raster file and generates centroids at that resolution. <br/>

Centroid dataframes are saved as CSV files with filenames that include the resolution and method used. <br/>

<br/>

----


## Function Arguments and Input

### template: <br/>
A file path to a template raster file that defines the grid resolution and extent. <br/>
Should be a processed NetCDF file from any of the download functions (`download_SILO_data`, `download_AGCD_data`, or `download_ANUClim_data`). <br/>
Required for both `"grid"` and `"sample"` methods. <br/>

Example: `"path_to_clim_data/daily_rain/processed/daily_rain_2020_processed.nc"` <br/>
<br/>


### sample_df: <br/>
A dataframe containing sample metadata with location information. <br/>
Required only when using `method = "sample"`. <br/>
Each row should represent a unique sample. <br/>

Must contain the following columns, named as described:

|Colname      |    Description            |
|:------------|:--------------------------|
| sample.id   | Unique sample identifier  |
| lat         | Latitude in decimal degrees |
| lon         | Longitude in decimal degrees |

Additional columns (e.g., date, elevation, collection info) can be present and will be retained in the output. <br/>

Example sample_df structure:
```
# 'data.frame':	428 obs. of  16 variables:
#  $ sample_name   : chr  "ANIC-14" "ANIC-16" "ANIC-17" "ANIC-18" ...
#  $ sample_no     : int  14 16 17 18 20 21 22 23 24 25 ...
#  $ subspp        : chr  "Abeona" "Abeona" "Abeona" "Abeona" ...
#  $ sex           : int  1 1 1 1 1 1 1 1 1 1 ...
#  $ measurer      : chr  "" "" "" "" ...
#  $ collection    : chr  "ANIC" "ANIC" "ANIC" "ANIC" ...
#  $ site          : chr  "" "" "" "" ...
#  $ lat           : num  -35.6 -35.6 -35.1 -35.7 -35.7 ...
#  $ lon           : num  150 150 150 150 150 ...
#  $ elev          : int  28 2 605 16 0 869 605 2 30 28 ...
#  $ sampling_date : chr  "22/03/1969" "25/10/1956" "29/11/1962" "22/01/1963" ...
#  $ sampling_year : int  1969 1956 1962 1963 1969 1962 1962 1936 1962 1969 ...
#  $ sampling_month: int  3 10 11 1 10 2 11 10 2 3 ...
#  $ sampling_day  : int  22 25 29 22 4 16 29 25 28 22 ...
#  $ sampling_yrday: int  81 299 333 22 277 47 333 299 59 81 ...
#  $ gen_cycle     : int  -1 1 1 1 1 -1 1 1 -1 -1 ...
```
<br/>


### method: <br/>
A character string specifying which method to use. <br/>

Options:
- `"grid"` - Extracts centroids for every cell in the entire cropped sampling region
- `"sample"` - Extracts centroids only for grid cells containing samples, rounding sample coordinates to the appropriate resolution

<br/>


### directory: <br/>
A file path specifying the directory where the output CSV file will be saved. <br/>
The filename is automatically generated based on the resolution and method used. <br/>

Output filenames:
- Grid method: `region.grid_centroids_res=[resolution].csv`
- Sample method: `sample_centroids_res=[resolution].csv`

<br/>

----


## Output

**For method = "grid":**

Returns and saves a dataframe with centroids for all grid cells in the raster:

|Column Name  | Description |
|:------------|:------------|
| centroid.id | Unique identifier for each grid cell |
| lat         | Latitude of cell centroid (decimal degrees) |
| lon         | Longitude of cell centroid (decimal degrees) |

Example output structure:
```
  centroid.id      lat       lon
1           1 -43.975  140.025
2           2 -43.975  140.075
3           3 -43.975  140.125
...
```

This output is used as input for `extract_and_compile_clim.data`. <br/>

<br/>

**For method = "sample":**

Returns and saves a dataframe with all original sample metadata plus rounded coordinates:

|Column Name  | Description |
|:------------|:------------|
| sample.id   | Sample identifier (from input) |
| raw_lat     | Original latitude from input data |
| raw_lon     | Original longitude from input data |
| lat         | Rounded latitude matching grid resolution |
| lon         | Rounded longitude matching grid resolution |
| centroid.id | Unique identifier for each unique grid cell |
| ...         | All other columns from input sample_df |

Samples in the same grid cell will have identical `lat`, `lon`, and `centroid.id` values. <br/>

This output is used as input for `assign_clim.data`. <br/>

<br/>

The output is saved as a CSV file with the resolution encoded in the filename. <br/>

<br/>

----


## Notes:

- The function automatically extracts the resolution from the template raster - no need to specify it manually

<br/>

- When using `method = "sample"`, the function rounds coordinates to the nearest grid cell centroid, ensuring samples are correctly mapped to their corresponding climate data cells

<br/>

- For `method = "sample"`, duplicate grid cells (multiple samples in the same cell) are reduced to unique centroids, but the full sample metadata is retained

<br/>

- The template raster can be from any climate data source (SILO, AGCD, or ANUClimate), but should match the resolution of the data you'll be working with

<br/>

- Grid method outputs can be large for fine-resolution rasters over large extents

<br/>

- Sample method is computationally lighter as it only processes locations where samples exist


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/make_cell_centroids_df.R")
```

<br/>

Generate grid centroids for all cells in the study region (for `extract_and_compile_clim.data`):
```
grid_centroids <- make_cell_centroids_df(
                      template = "path_to_clim_data/daily_rain/processed/daily_rain_2020_processed.nc",
                      sample_df = NULL,
                      method = "grid",
                      directory = "path_to_save_location")
```

<br/>

Generate sample centroids by rounding individual coordinates to grid resolution (for `assign_clim.data`):
```
# First load your sample metadata
sample_metadata <- read.csv("path_to_metadata/sample_locations.csv")

# Then generate centroids
sample_centroids <- make_cell_centroids_df(
                        template = "path_to_clim_data/daily_rain/processed/daily_rain_2020_processed.nc",
                        sample_df = sample_metadata,
                        method = "sample",
                        directory = "path_to_save_location")
```

<br/>

Generate centroids using a rescaled ANUClimate template (if combining data sources):
```
grid_centroids <- make_cell_centroids_df(
                      template = "path_to_clim_data/t_max/rescaled/t_max_2020_rescaled.nc",
                      sample_df = NULL,
                      method = "grid",
                      directory = "path_to_save_location")
```

<br/>

Generate sample centroids and verify coordinate rounding:
```
sample_metadata <- read.csv("path_to_metadata/sample_locations.csv")

sample_centroids <- make_cell_centroids_df(
                        template = "path_to_clim_data/tmax/processed/tmax_2020_processed.nc",
                        sample_df = sample_metadata,
                        method = "sample",
                        directory = "path_to_save_location")

# Check how coordinates were rounded
head(sample_centroids[, c("sample.id", "raw_lat", "lat", "raw_lon", "lon")])
```





<br/>

----


<br/>
