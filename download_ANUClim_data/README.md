# download_ANUClim_data



##  Description. 

A function to download monthly raster grids of daily climate data from the ANUClimate 2.0 database for user specified years and climate variables. <br/>

Unlike AGCD and SILO which provide annual files, ANUClimate data is distributed as monthly files. This function handles the additional complexity of downloading 12 monthly files per year per variable, processing them individually, and then compiling them into annual rasters for compatibility with downstream functions. <br/>

The function automatically creates a directory structure to store downloaded files, with separate folders for each climate variable within the user-specified directory (e.g., `user_directory/rain`). <br/>

**Monthly raw downloads** are saved to a `monthly` subdirectory within each variable folder (e.g., `user_directory/rain/monthly`). <br/>

**Processed monthly files** (cropped and reprojected) are saved to a `monthly_processed` subdirectory (e.g., `user_directory/rain/monthly_processed`). <br/>

**Annual compiled files** (stacked from 12 monthly files) are saved to a `processed` subdirectory (e.g., `user_directory/rain/processed`). <br/>

All monthly rasters are automatically reprojected to CRS:4326 for compatibility with other data sources and cropped using a user-supplied shapefile to reduce file size and computational load. The 12 monthly rasters for each year are then stacked into a single annual raster (preserving daily time steps) for compatibility with other data sources and downstream functions. <br/>

**Important:** To avoid naming conflicts with AGCD temperature variables, ANUClimate temperature variables are automatically renamed: `tmin` becomes `t_min` and `tmax` becomes `t_max`. <br/>

<br/>

----


## Function Arguments and Input

### first_year: <br/>
An integer specifying the first year from which to download climate data. <br/>
Must be 1900 or later (the earliest year for which ANUClimate data is available). <br/>
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


### anuclim_clim.var: <br/>
A character vector of climate variable names matching those used by the ANUClimate database. <br/>

Available variables and their earliest data availability:

|Variable                       |    ANUClimate Name | Available From | Output Name |
|:------------------------------|:------------------:|:--------------:|:-----------:|
|Precipitation                  | rain               |     1900       | rain        |
|Maximum Temperature            | tmax               |     1960       | t_max       |
|Minimum Temperature            | tmin               |     1960       | t_min       |
|Average Temperature            | tavg               |     1960       | tavg        |
|Solar Radiation                | srad               |     1960       | srad        |
|Class A Pan Evaporation        | evap               |     1970       | evap        |
|Vapour Pressure                | vp                 |     1960       | vp          |
|Vapour Pressure Deficit        | vpd                |     1960       | vpd         |

**Note:** `tmin` and `tmax` are automatically renamed to `t_min` and `t_max` to avoid conflicts with AGCD variable names. <br/>

Example: `c("rain", "tmax", "tmin", "srad")` <br/>
<br/>


### directory: <br/>
A file path specifying the directory where downloaded data will be saved. <br/>
Formatted as `"../folder1/subfolder"`. <br/>
The function will create subdirectories for each variable, with `monthly`, `monthly_processed`, and `processed` folders within. <br/>
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
A logical value determining whether to overwrite existing raw monthly downloaded files. <br/>
Default: `FALSE` <br/>

- If `FALSE` and a monthly raw file already exists, the function will skip downloading that month and either process it (if `overwrite_crop = TRUE`) or move to the next month
- If `TRUE`, all monthly files will be re-downloaded regardless of whether they already exist

<br/>


### overwrite_crop: <br/>
A logical value determining whether to overwrite existing processed monthly files (cropped and reprojected). <br/>
Default: `FALSE` <br/>

- If `FALSE` and processed monthly files already exist, the function will use existing files for annual compilation
- If `FALSE` but processed monthly files don't exist, new processed files will be created from existing raw downloads
- If `TRUE`, all monthly files will be reprocessed (cropped and reprojected) and saved

<br/>


### overwrite_compile: <br/>
A logical value determining whether to overwrite existing annual compiled files. <br/>
Default: `FALSE` <br/>

- If `FALSE` and the annual processed file already exists, the function will skip that year entirely (no monthly downloads or processing)
- If `FALSE` but the annual processed file doesn't exist, monthly files will be compiled into an annual file
- If `TRUE`, all monthly files will be recompiled into annual files

<br/>

----


## Output

The function creates the following directory structure:

```
user_directory/
  ├── variable_1/
  │   ├── monthly/
  │   │   ├── variable_1_year1_01_monthly.nc
  │   │   ├── variable_1_year1_02_monthly.nc
  │   │   ├── ...
  │   │   └── variable_1_year1_12_monthly.nc
  │   ├── monthly_processed/
  │   │   ├── variable_1_year1_01_processed_month.nc
  │   │   ├── variable_1_year1_02_processed_month.nc
  │   │   ├── ...
  │   │   └── variable_1_year1_12_processed_month.nc
  │   └── processed/
  │       ├── variable_1_year1_processed.nc
  │       ├── variable_1_year2_processed.nc
  │       └── ...
  ├── variable_2/
  │   ├── monthly/
  │   ├── monthly_processed/
  │   └── processed/
  └── ...
```

**Monthly files** contain raw downloaded monthly rasters (12 files per year) in their original projection. <br/>

**Monthly processed files** contain monthly rasters that have been:
- Reprojected to WGS84 (EPSG:4326)
- Cropped to the extent of the user-supplied shapefile
- Masked to the polygon boundaries

**Annual processed files** contain:
- All 12 months stacked into a single annual raster
- Daily time steps preserved (365 or 366 layers depending on leap year)
- Proper date attribution for each layer
- Reprojected to WGS84 (EPSG:4326)
- Cropped and masked to the user-supplied shapefile

All files are saved in NetCDF format (.nc) with compression. <br/>

The function provides detailed progress messages indicating which months and years are being downloaded, processed, and compiled for each variable. <br/>

<br/>

----


## Notes:

- ANUClimate data has a resolution of 0.01° × 0.01° (higher resolution than AGCD and SILO at 0.05° × 0.05°)
- If using ANUClimate variables alongside AGCD or SILO variables, use the `rescale_rasters` function to match resolutions
- Different variables have different start dates - the function will automatically skip years for which data is unavailable and inform the user
- The function verifies that all 12 monthly files are present before compiling to an annual raster
- The function checks for correct number of days per month (accounting for leap years)
- Temperature variables from ANUClimate (`tmin`, `tmax`) are automatically renamed to `t_min` and `t_max` to prevent conflicts with AGCD variable names
- Monthly files are retained after processing, allowing reprocessing or recompilation without re-downloading
- Ensure adequate disk space is available - ANUClimate files are larger due to higher resolution and the storage of both monthly and annual files
- The cropping shapefile should have a buffer of at least one grid cell around your area of interest to prevent edge effects
- Auxiliary files (.aux, .aux.xml, .json) are automatically cleaned up after processing
- If compilation fails for a year (e.g., missing months or layer count mismatch), that year will be skipped with a warning message


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/download_ANUClim_data.R")
```

<br/>

Download precipitation, maximum temperature, minimum temperature, and solar radiation data for years 2015-2020:
```
download_ANUClim_data(first_year = 2015,
                      last_year = 2020,
                      year_interval = 1,
                      anuclim_clim.var = c("rain", "tmax", "tmin", "srad"),
                      directory = "path_to_save_location/clim_data",
                      crop_shape = "path_to_shapefile/region_boundary.shp",
                      overwrite_download = FALSE,
                      overwrite_crop = FALSE,
                      overwrite_compile = FALSE)
```

<br/>

Download data at 5-year intervals:
```
download_ANUClim_data(first_year = 1960,
                      last_year = 2020,
                      year_interval = 5,
                      anuclim_clim.var = c("rain", "tmax", "tmin"),
                      directory = "path_to_save_location/clim_data",
                      crop_shape = "path_to_shapefile/region_boundary.shp",
                      overwrite_download = FALSE,
                      overwrite_crop = FALSE,
                      overwrite_compile = FALSE)
```

<br/>

Reprocess and recompile existing monthly downloads with a new crop extent:
```
download_ANUClim_data(first_year = 2015,
                      last_year = 2020,
                      year_interval = 1,
                      anuclim_clim.var = c("tmax", "tmin", "vp"),
                      directory = "path_to_save_location/clim_data",
                      crop_shape = "path_to_shapefile/new_region_boundary.shp",
                      overwrite_download = FALSE,
                      overwrite_crop = TRUE,
                      overwrite_compile = TRUE)
```

<br/>

Force complete re-download and reprocessing of all data:
```
download_ANUClim_data(first_year = 2018,
                      last_year = 2020,
                      year_interval = 1,
                      anuclim_clim.var = c("rain", "tavg"),
                      directory = "path_to_save_location/clim_data",
                      crop_shape = "path_to_shapefile/region_boundary.shp",
                      overwrite_download = TRUE,
                      overwrite_crop = TRUE,
                      overwrite_compile = TRUE)
```





<br/>

----


<br/>
