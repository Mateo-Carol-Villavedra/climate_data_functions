# download_SILO_data



##  Description. 

A function to download annual raster grids of daily climate data from the SILO (Scientific Information for Land Owners) database for user specified years and climate variables. <br/>

The function automatically creates a directory structure to store downloaded files, with separate folders for each climate variable within the user-specified directory (e.g., `user_directory/daily_rain`). <br/>

Raw downloads are saved to a `raw` subdirectory within each variable folder (e.g., `user_directory/daily_rain/raw`). <br/>

All downloaded rasters are automatically reprojected to CRS:4326 for compatibility with other data sources and cropped using a user-supplied shapefile to reduce file size and computational load in downstream analyses. <br/>

Processed (reprojected and cropped) rasters are saved to a `processed` subdirectory within each variable folder (e.g., `user_directory/daily_rain/processed`). <br/>

<br/>

----


## Function Arguments and Input

### first_year: <br/>
An integer specifying the first year from which to download climate data. <br/>
Must be 1889 or later (the earliest year for which SILO data is available). <br/>
<br/>


### last_year: <br/>
An integer specifying the last year from which to download climate data. <br/>
Must be equal to or greater than `first_year`. <br/>
<br/>


### year_interval: <br/>
An integer specifying the interval between years for data download. <br/>
- `1` = every year
- `2` = every second year
- `10` = once per decade, etc.

Must be 1 or greater. <br/>
<br/>


### silo_clim.var: <br/>
A character vector of climate variable names matching those used by the SILO database. <br/>

Available variables (all available from 1889):

|Variable                                                       |    SILO Name           | Available From |
|:--------------------------------------------------------------|:----------------------:|:--------------:|
|Precipitation                                                  | daily_rain             |     1889       |
|Maximum Temperature                                            | max_temp               |     1889       |
|Minimum Temperature                                            | min_temp               |     1889       |
|Solar Radiation (Both Direct and Diffuse Components)           | radiation              |     1889       |
|Vapour Pressure                                                | vp                     |     1889       |
|Vapour Pressure Deficit                                        | vp_deficit             |     1889       |
|Class A Pan Evaporation                                        | evap_pan               |     1889       |
|Synthetic Estimate                                             | evap_syn               |     1889       |
|Combination Estimate (Pre-1970 = Synthetic, Post-1970 = Pan)   | evap_comb              |     1889       |
|Morton Shallow Lake Evaporation                                | evap_morton_lake       |     1889       |
|Relative Humidity at time of Maximum Daily Temperature         | rh_tmax                |     1889       |
|Relative Humidity at time of Minimum Daily Temperature         | rh_tmin                |     1889       |
|FAO56 Short Crop                                               | et_short_crop          |     1889       |
|ASCE Tall Crop                                                 | et_tall_crop           |     1889       |
|Morton's Areal Actual Evapotranspiration                       | et_morton_actual       |     1889       |
|Morton's Point Potential Evapotranspiration                    | et_morton_potential    |     1889       |
|Morton's Wet-Environment Areal Potential Evapotranspiration    | et_morton_wet          |     1889       |
|Mean Sea Level Pressure                                        | mslp                   |     1889       |

Example: `c("daily_rain", "max_temp", "min_temp", "radiation")` <br/>
<br/>


### directory: <br/>
A file path specifying the directory where downloaded data will be saved. <br/>
Formatted as `"../folder1/subfolder"`. <br/>
The function will create subdirectories for each variable, with `raw` and `processed` folders within. <br/>
<br/>


### crop_shape: <br/>
A shapefile of a polygon that entirely encompasses the desired region for data extraction. <br/>
Used to crop rasters after downloading to reduce file size and computational load. <br/>

- Can be provided as either:
  - A file path to a shapefile (character string)
  - A `terra` SpatVector object
- Must be in CRS:4326
- The polygon must be valid (no overlapping vertices or borders)
- Should include a margin of a few grid cells beyond the area of interest to ensure all required data points are preserved, as slight mismatches between climate databases regarding raster extent can cause issues downstream

<br/>


### overwrite_download: <br/>
A logical value determining whether to overwrite existing raw downloaded files. <br/>
Default: `FALSE` <br/>

- If `FALSE` and the raw file already exists, the function will skip downloading and either process the existing file (if `overwrite_crop = TRUE`) or move to the next year
- If `TRUE`, all files will be re-downloaded regardless of whether they already exist

<br/>


### overwrite_crop: <br/>
A logical value determining whether to overwrite existing processed (cropped and reprojected) files. <br/>
Default: `FALSE` <br/>

- If `FALSE` and processed files already exist, the function will skip processing and move to the next year
- If `FALSE` but processed files don't exist, new processed files will be created from existing raw downloads
- If `TRUE`, all files will be reprocessed (cropped and reprojected) and saved

<br/>

----


## Output

The function creates the following directory structure:

```
user_directory/
  ├── variable_1/
  │   ├── raw/
  │   │   ├── variable_1_year1_raw.nc
  │   │   ├── variable_1_year2_raw.nc
  │   │   └── ...
  │   └── processed/
  │       ├── variable_1_year1_processed.nc
  │       ├── variable_1_year2_processed.nc
  │       └── ...
  ├── variable_2/
  │   ├── raw/
  │   └── processed/
  └── ...
```

**Raw files** contain downloaded annual rasters in their original projection (EPSG:4283). <br/>

**Processed files** contain rasters that have been:
- Reprojected to WGS84 (EPSG:4326)
- Cropped to the extent of the user-supplied shapefile
- Masked to the polygon boundaries

All files are saved in NetCDF format (.nc) with compression. <br/>

The function provides progress messages indicating which years are being downloaded and processed for each variable. <br/>

<br/>

----


## Notes:

- SILO data has a resolution of 0.05° × 0.05°
- All SILO variables are available from 1889, providing the longest temporal coverage of the three databases
- SILO offers the most comprehensive range of climate variables, including multiple evapotranspiration estimates and solar radiation
- Ensure adequate disk space is available, as climate raster files can be large, especially for extended time periods or large spatial extents
- The cropping shapefile should have a buffer of at least one grid cell around your area of interest to prevent edge effects
- Raw files are retained after processing, allowing reprocessing with different crop extents without re-downloading
- Auxiliary files (.aux, .aux.xml, .json) are automatically cleaned up after processing


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/download_SILO_data.R")
```

<br/>

Download precipitation, maximum temperature, minimum temperature, and solar radiation data for years 2015-2020:
```
download_SILO_data(first_year = 2015,
                   last_year = 2020,
                   year_interval = 1,
                   silo_clim.var = c("daily_rain", "max_temp", "min_temp", "radiation"),
                   directory = "path_to_save_location/clim_data",
                   crop_shape = "path_to_shapefile/region_boundary.shp",
                   overwrite_download = FALSE,
                   overwrite_crop = FALSE)
```

<br/>

Download data at 10-year intervals from the full SILO time series:
```
download_SILO_data(first_year = 1889,
                   last_year = 2020,
                   year_interval = 10,
                   silo_clim.var = c("daily_rain", "max_temp", "min_temp"),
                   directory = "path_to_save_location/clim_data",
                   crop_shape = "path_to_shapefile/region_boundary.shp",
                   overwrite_download = FALSE,
                   overwrite_crop = FALSE)
```

<br/>

Reprocess existing downloads with a new crop extent:
```
download_SILO_data(first_year = 2015,
                   last_year = 2020,
                   year_interval = 1,
                   silo_clim.var = c("radiation", "vp"),
                   directory = "path_to_save_location/clim_data",
                   crop_shape = "path_to_shapefile/new_region_boundary.shp",
                   overwrite_download = FALSE,
                   overwrite_crop = TRUE)
```





<br/>

----


<br/>
