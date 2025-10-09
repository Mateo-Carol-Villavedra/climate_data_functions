# compute_ind_bioclims



##  Description. 

A function to compute bioclimatic indices (BIO1-BIO27) for each individual sample based on their assigned climate data from the `assign_clim.data` function. <br/>

**NOTE:** This function is designed to compute bioclimatic indices assuming each sample has exactly **1 year (365 or 366 days) of climate data**. The output will not be accurate if a different time period is provided. When using `assign_clim.data`, ensure the pre_period and post_period sum to exactly one year. <br/>

The function computes bioclimatic indices using daily values for maximum temperature, minimum temperature, precipitation, and/or radiation, allowing users to select which indices to compute and which climate variables to use. <br/>

Users can combine variables from any combination of the three databases (SILO, AGCD, ANUClimate), and the function intelligently handles synonymous variable names (e.g., `tmax`, `max_temp`, `t_max` all represent maximum temperature). <br/>

The function will only fail if specific climate variables required for the requested indices are missing. Not all 4 climate variable types are needed unless computing all 27 indices. <br/>

Results are saved as an RDS file containing a dataframe with one row per sample and columns for each computed bioclimatic index. <br/>

<br/>

----


## Function Arguments and Input

### ind.clim_meta: <br/>
The dataframe produced by the `assign_clim.data` function containing individual sample climate data. <br/>

**CRITICAL:** Each sample must have exactly 1 year (365 or 366 days) of climate data. <br/>

Must contain:
- `sample.id` - unique sample identifier
- `date` - sample collection date
- `clim_date` - date of climate observation
- Climate variable columns (e.g., `tmax`, `tmin`, `precip`, `radiation`, etc.)
- `lat`, `lon` - location coordinates

<br/>


### bioclim_indices: <br/>
A numeric vector specifying which bioclimatic indices to compute. <br/>
      Values range from 1 to 27. <br/>
      
  Example: `c(1, 2, 3, 4, 5, 6, 7, 8, 15, 22, 21, 26)`
  
  <br/>  

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
  
**See Carol Villavedra et al. (2026) Supplementary Materials for Specific Arithmetic used to Compute Each Bioclimatic Index.**    

  
  <br/>


### var.names: <br/>
A character vector specifying which climate variables to use for computing bioclimatic indices. <br/>

The function handles synonymous variable names from different data sources:

|Climate Variable     | AGCD Name | SILO Name   | ANUClimate Name |
|:--------------------|:----------|:------------|:----------------|
|Maximum Temperature  | tmax      | max_temp    | t_max           |
|Minimum Temperature  | tmin      | min_temp    | t_min           |
|Precipitation        | precip    | daily_rain  | rain            |
|Radiation            | —         | radiation   | srad            |

**Important:** Only specify **one** variable name per climate type. For example, use either `"tmax"` OR `"max_temp"` OR `"t_max"`, but not multiple. The function will return an error if multiple synonymous variables are specified. <br/>

Example: `c("tmax", "tmin", "precip", "radiation")` <br/>
Example: `c("max_temp", "min_temp", "daily_rain", "radiation")` <br/>
Example: `c("t_max", "t_min", "rain", "srad")` <br/>
<br/>


### output_directory: <br/>
A file path specifying where to save the computed bioclimatic indices as an RDS file. <br/>
Include the `.RDS` extension in the filename. <br/>

Example: `"path_to_save_location/individual_bioclim_indices.RDS"` <br/>
<br/>

----


## Output

Returns and saves a dataframe with one row per sample and columns for each computed bioclimatic index. <br/>

**Output structure:**

|Column Name | Description |
|:-----------|:------------|
| sample.id  | Unique sample identifier |
| bio1       | BIO1 value (if requested) |
| bio2       | BIO2 value (if requested) |
| ...        | Additional requested indices |
| bioN       | BION value (if requested) |

Only the indices specified in `bioclim_indices` will be included as columns. <br/>

The dataframe is saved as an RDS file at the specified output path and returned to the user. <br/>

<br/>

----


## Notes:

- **Critical time period requirement:** Each sample MUST have exactly 1 year (365 or 366 days) of climate data for accurate bioclimatic index calculation

<br/>

- When using `assign_clim.data`, set the time period so that `pre_period + post_period + sampling date = 1 year`

<br/>

- The function automatically handles synonymous variable names from different data sources (SILO, AGCD, ANUClimate)

<br/>

- If multiple synonymous variables exist in the input data (e.g., both `tmax` and `max_temp`), specify only one in `var.names` - the function will remove the others and standardize naming

<br/>

- Leap years (366 days) are handled automatically

<br/>

- The function performs monthly and quarterly aggregations as intermediate steps to compute various indices

<br/>

- Processing time depends on the number of samples, indices requested, and variables included


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/compute_ind_bioclims.R")
```

<br/>

Load the individual climate data produced by `assign_clim.data`:
```
ind_climate_data <- readRDS("path_to_data/individuals_climate_assigned.RDS")
```

<br/>

Compute all temperature and precipitation indices using SILO variables:
```
ind_bioclims <- compute_ind_bioclims(
                    ind.clim_meta = ind_climate_data,
                    bioclim_indices = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 
                                        12, 13, 14, 15, 16, 17, 18, 19),
                    var.names = c("max_temp", "min_temp", "daily_rain"),
                    output_directory = "path_to_save_location/ind_bioclim_indices.RDS")
```

<br/>

Compute selected temperature indices using AGCD variables:
```
ind_bioclims <- compute_ind_bioclims(
                    ind.clim_meta = ind_climate_data,
                    bioclim_indices = c(1, 2, 5, 6, 7),
                    var.names = c("tmax", "tmin"),
                    output_directory = "path_to_save_location/ind_temp_indices.RDS")
```

<br/>

Compute all 27 bioclimatic indices using mixed data sources (SILO + ANUClimate):
```
ind_bioclims <- compute_ind_bioclims(
                    ind.clim_meta = ind_climate_data,
                    bioclim_indices = c(1:27),
                    var.names = c("max_temp", "min_temp", "daily_rain", "srad"),
                    output_directory = "path_to_save_location/all_bioclim_indices.RDS")
```

<br/>

Compute radiation-only indices using ANUClimate variables:
```
ind_bioclims <- compute_ind_bioclims(
                    ind.clim_meta = ind_climate_data,
                    bioclim_indices = c(20, 21, 22, 23),
                    var.names = c("srad"),
                    output_directory = "path_to_save_location/radiation_indices.RDS")
```

<br/>

Compute custom selection of indices from different categories:
```
ind_bioclims <- compute_ind_bioclims(
                    ind.clim_meta = ind_climate_data,
                    bioclim_indices = c(1, 3, 8, 9, 10, 14, 15, 22, 25),
                    var.names = c("tmin", "tmax", "daily_rain", "radiation"),
                    output_directory = "path_to_save_location/selected_indices.RDS")
```

<br/>

Load and inspect computed indices:
```
# Load the saved RDS file
bioclim_data <- readRDS("path_to_save_location/ind_bioclim_indices.RDS")

# Check structure
str(bioclim_data)

# View first few rows
head(bioclim_data)

# Summary statistics
summary(bioclim_data)

# Check for missing values
colSums(is.na(bioclim_data))
```





<br/>

----


<br/>
