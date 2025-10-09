# rescale_rasters



##  Description. 

A function to rescale downloaded and processed raster grids to match the resolution of a user-supplied template raster. <br/>

**NOTE:** This function is only necessary when combining ANUClimate variables with SILO or AGCD variables. <br/>

This function is specifically designed to facilitate using climate variables from ANUClimate 2.0 (resolution: 0.01° × 0.01°) alongside variables from SILO or AGCD (resolution: 0.05° × 0.05°). <br/>

The function rescales ANUClimate rasters to match the resolution of a template raster file from SILO or AGCD. The template raster **must** have a coarser resolution than the rasters being rescaled. <br/>

Since AGCD and SILO have identical resolutions (0.05° × 0.05°), only one template file is required even when using variables from all three data sources. <br/>

The function handles different variable types during rescaling:
- **Precipitation, evaporation, and evapotranspiration variables:** values are **summed** across cells to retain total values
- **All other variables (temperature, vapour pressure, radiation, etc.):** values are **averaged** across cells

Rescaled raster files are saved into a `rescaled` subdirectory within each variable directory (e.g., `user_directory/rain/rescaled`). <br/>

<br/>

----


## Function Arguments and Input

### var_directories: <br/>
A character vector of file paths to ANUClimate variable directories that need to be rescaled. <br/>
Each directory should contain a `processed` subdirectory with annual NetCDF files produced by the `download_ANUClim_data` function. <br/>

Example: `c("path_to_clim_data/t_min", "path_to_clim_data/t_max", "path_to_clim_data/rain")` <br/>
<br/>


### template_file: <br/>
A file path to a template raster file that defines the target grid specifications. <br/>
Should be a processed NetCDF file from either SILO or AGCD (output from `download_SILO_data` or `download_AGCD_data`). <br/>
The template raster must have a coarser resolution than the ANUClimate rasters being rescaled. <br/>

Example: `"path_to_clim_data/daily_rain/processed/daily_rain_2020_processed.nc"` <br/>
<br/>

----


## Output

The function creates a `rescaled` subdirectory within each variable directory provided:

```
user_directory/
  ├── variable_1/
  │   ├── monthly/
  │   ├── monthly_processed/
  │   ├── processed/
  │   └── rescaled/
  │       ├── variable_1_year1_rescaled.nc
  │       ├── variable_1_year2_rescaled.nc
  │       └── ...
  ├── variable_2/
  │   ├── ...
  │   └── rescaled/
  └── ...
```

**Rescaled files** contain rasters that have been:
- Resampled to match the resolution of the template raster (typically from 0.01° × 0.01° to 0.05° × 0.05°)
- Processed using either sum (for precipitation/evaporation/evapotranspiration) or average (for all other variables) methods
- Reprojected to match the CRS of the template raster (if necessary)
- Saved with preserved time metadata and layer names

All files are saved in NetCDF format (.nc) with compression. <br/>

The function provides detailed progress messages for each file processed, including input/output resolutions and the number of layers. <br/>

<br/>

----


## Notes:

- **This function is only necessary when combining ANUClimate variables with SILO or AGCD variables**

<br/>

- ANUClimate data has a higher resolution (0.01° × 0.01°) than SILO and AGCD (0.05° × 0.05°)

<br/>

- The template raster defines the target grid - all rescaled rasters will match its resolution, extent, and CRS
  - Since AGCD and SILO have identical resolutions, a template from either source can be used

<br/>

- The function automatically detects variable types and applies appropriate aggregation methods:
  - **Summed variables:** `precip`, `daily_rain`, `rain`, `evap_pan`, `evap_syn`, `evap_comb`, `evap_morton_lake`, `evap`, `et_short_crop`, `et_tall_crop`, `et_morton_lake`, `et_morton_potential`, `et_morton_wet`
  - **Averaged variables:** All others (temperature, vapour pressure, radiation, humidity, pressure, etc.)

<br/>

- Time metadata and layer names are preserved during rescaling

<br/>

- The function processes all annual NetCDF files in each variable's `processed` directory

<br/>

- Ensure adequate disk space is available as rescaled files are stored separately from the original files


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/rescale_rasters.R")
```

<br/>

Then ensure you have:
1. Downloaded and processed ANUClimate variables using `download_ANUClim_data`
2. Downloaded and processed at least one SILO or AGCD variable to use as a template

<br/>

Rescale ANUClimate temperature and precipitation variables to match SILO resolution:
```
rescale_rasters(var_directories = c("path_to_clim_data/t_min", 
                                    "path_to_clim_data/t_max", 
                                    "path_to_clim_data/rain",
                                    "path_to_clim_data/srad",),
                template_file = "path_to_clim_data/daily_rain/processed/daily_rain_2020_processed.nc")
```

<br/>

----


<br/>
