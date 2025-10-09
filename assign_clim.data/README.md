# assign_clim.data



##  Description. 

A function to assign climate data for a user-defined temporal period to each individual sample based on their location and sampling date. This function extracts climate data for each individual from the long-format dataframe produced as the output of `extract_and_compile_clim.data`. <br/>

Each individual is mapped to a grid cell based on latitude and longitude coordinates which should be rounded to match the resolution of the source raster. This can be completed using the `make_cell_centroids_df` function with setting `method = "sample"`. <br/>

Each individual in the input `sample_df` is assigned daily climate data from the relevant grid cell for every day within a user-specified time period before and/or after the sampling date associated with each sample. <br/>

This results in each individual accumulating `d` rows, where `d` is the number of days in the user-specified period. <br/>

The resulting dataframe will have `nrow = d × nrow(sample_df)`, with the climate data for all selected variables for each day assigned to each sample. <br/>

**Critical User Requirement:** Users MUST ensure they have collected climate data for the required years based on both the individuals in their dataset AND the time period specified for climate data collection for each individual. <br/>

<br/>

----


## Function Arguments and Input

### grid_df: <br/>
The R dataframe output of the function `extract_and_compile_clim.data` or an R dataframe with identical characteristics. <br/>
Source from which climate data is extracted and assigned to each individual sample. <br/>
<br/>


### sample_df: <br/>
The output of the function `make_cell_centroids_df` using `method = "sample"` or an R dataframe with identical characteristics. <br/>
Metadata used to assign individuals to grid cells and to then assign climate data based on sampling date. <br/>

Must contain the following columns, named as described:

|Colname      |    Description            |
|:------------|:--------------------------|
| sample.id   | Unique sample identifier for each sample |
| lat         | Latitude for each sample (rounded to match the target resolution) |
| lon         | Longitude for each sample (rounded to match the target resolution) |
| date        | Date of collection of sample (a character string as "dd/mm/yyyy" - i.e., the 24th of December, 1965 as "24/12/1965") |

Additional columns (e.g., elevation, collection info) can be present and will be retained. <br/>

Example sample_df structure:
```
# 'data.frame':	428 obs. of  14 variables:
#  $ sample.id     : chr  "ANIC-14" "ANIC-16" "ANIC-17" "ANIC-18" ...
#  $ sample_no     : int  14 16 17 18 20 21 22 23 24 25 ...
#  $ subspp        : chr  "Abeona" "Abeona" "Abeona" "Abeona" ...
#  $ sex           : int  1 1 1 1 1 1 1 1 1 1 ...
#  $ collection    : chr  "ANIC" "ANIC" "ANIC" "ANIC" ...
#  $ lat           : num  -35.6 -35.6 -35.1 -35.7 -35.7 ...
#  $ lon           : num  150 150 150 150 150 ...
#  $ elev          : int  28 2 605 16 0 869 605 2 30 28 ...
#  $ date          : chr  "22/3/2020" "25/10/2020" "29/11/2020" "22/1/2020" ...
#  $ sampling_year : int  2020 2020 2020 2020 2020 2020 2020 2020 2020 2020 ...
#  $ sampling_month: int  3 10 11 1 10 2 11 10 2 3 ...
#  $ sampling_day  : int  22 25 29 22 4 16 29 25 28 22 ...
#  $ sampling_yrday: int  81 299 333 22 277 47 333 299 59 81 ...
#  $ gen_cycle     : int  -1 1 1 1 1 -1 1 1 -1 -1 ...
```
<br/>


### pre_period: <br/>
A numerical vector specifying the number of years, months, and days prior to the sampling date to include in the climate data collected for each sample. <br/>
Formatted as `c(years, months, days)`. <br/>

Examples:
- Capturing from 1 year prior to capture date: `c(1, 0, 0)`
- Capturing from 6 months prior to capture date: `c(0, 6, 0)`
- Capturing from 10 days prior to capture date: `c(0, 0, 10)`
- Capturing from 2 years, 9 months and 4 days prior to capture date: `c(2, 9, 4)`

<br/>


### include_start_date: <br/>
A logical value determining whether the date at the boundary of the `pre_period` is included in the relevant period. <br/>

- `TRUE` - Include the start boundary date
- `FALSE` - Exclude the start boundary date

<br/>


### post_period: <br/>
A numerical vector specifying the number of years, months, and days after the sampling date to include in the climate data collected for each sample. <br/>
Formatted as `c(years, months, days)`. <br/>

Examples:
- Capturing until 1 year after capture date: `c(1, 0, 0)`
- Capturing until 6 months after capture date: `c(0, 6, 0)`
- Capturing until 10 days after capture date: `c(0, 0, 10)`
- Capturing until 2 years, 9 months and 4 days after capture date: `c(2, 9, 4)`

<br/>


### include_end_date: <br/>
A logical value determining whether the date at the boundary of the `post_period` is included in the relevant period. <br/>

- `TRUE` - Include the end boundary date
- `FALSE` - Exclude the end boundary date

<br/>


### output_directory: <br/>
A file path specifying where to save the output as an RDS file. <br/>
Must include the filename and `.RDS` extension. <br/>

Example: `"path_to_save_location/individuals_climate_assigned.RDS"` <br/>

<br/>

----


## Output

Each individual in the input `sample_df` is assigned daily climate data from the relevant grid cell for every day within the user-specified time periods before and/or after the date associated with each sample. <br/>

This results in each individual accumulating `d` rows, where `d` is the number of days in the user-specified period. <br/>

The resulting dataframe will have `nrow = d × nrow(sample_df)`, with the climate data for all selected variables for each day assigned to each sample. <br/>

**Output structure:**

|Column Name    | Description |
|:--------------|:------------|
| sample.id     | Unique sample identifier |
| lat           | Latitude of sample location |
| lon           | Longitude of sample location |
| centroid.id   | Grid cell identifier |
| clim_date     | Date of climate observation |
| date          | Original sample collection date |
| [variable_1]  | Climate values for variable 1 |
| [variable_2]  | Climate values for variable 2 |
| ...           | Additional climate variables from grid_df |

All other columns from the original `sample_df` are preserved in the output. <br/>

The resulting dataframe is returned to the user and saved as an `.RDS` file at the filepath specified by the `output_directory` argument. <br/>

The function provides a summary message indicating:
- The number of individuals processed
- A table showing the distribution of record counts per individual
- A reminder that all individuals should have the same number of records (with potential exception for leap years)

<br/>

----


## Notes:

- **Critical temporal coverage requirement:** Ensure the climate data in `grid_df` covers all dates needed for your samples. If a sample was collected in 2015 and you specify `pre_period = c(1, 0, 0)`, you need climate data back to 2014
- **Time period flexibility:** The function allows asymmetric time periods - you can collect data only before, only after, or both before and after the sampling date
- **Boundary date control:** Use `include_start_date` and `include_end_date` to fine-tune exactly which dates are included, which is important for ensuring the correct number of days (especially for bioclimatic index calculations)
- **Record count verification:** After running, check that individuals each have the correct number of days based on your specified periods. You may need to adjust the boundary date controls to achieve the exact time period needed
- **Leap year handling:** The function automatically handles leap years, but this may result in some individuals having 365 days and others having 366 days if their climate period spans different years
- **Coordinate matching:** Sample coordinates must exactly match the resolution of the grid_df centroids (rounded using `make_cell_centroids_df`)
- **Date format:** Input dates must be in "dd/mm/yyyy" format (e.g., "24/12/1965")
- **Missing data:** If no climate data is found for a sample's location and time period, that sample will have zero rows in the output


<br/>

----




## Usage Examples:

First, load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/assign_clim.data.R")
```

<br/>

Load the compiled climate data produced by `extract_and_compile_clim.data`:
```
compiled_clim_raster_df <- readRDS("path_to_output_df/compiled_climate_data.RDS")
```

<br/>

Load the sample metadata dataframe produced by `make_cell_centroids_df` using `method = "sample"`:
```
ind_centroids <- read.csv("path_to_ind_centroids_df/sample_centroids_res=0.05.csv")
```

<br/>

Assign 1 year of climate data prior to sampling date (for bioclimatic index calculation):
```
ind_climate_assigned <- assign_clim.data(
                            grid_df = compiled_clim_raster_df,
                            sample_df = ind_centroids,
                            pre_period = c(1, 0, 0),
                            include_start_date = FALSE,
                            post_period = c(0, 0, 0),
                            include_end_date = TRUE,
                            output_directory = "path_to_save_location/ind_climate_1yr_prior.RDS")
```

<br/>

Assign climate data for 6 months before and 6 months after sampling date:
```
ind_climate_assigned <- assign_clim.data(
                            grid_df = compiled_clim_raster_df,
                            sample_df = ind_centroids,
                            pre_period = c(0, 6, 0),
                            include_start_date = TRUE,
                            post_period = c(0, 6, 0),
                            include_end_date = TRUE,
                            output_directory = "path_to_save_location/ind_climate_12months.RDS")
```

<br/>

Assign climate data for 2 years prior to sampling (including sampling day):
```
ind_climate_assigned <- assign_clim.data(
                            grid_df = compiled_clim_raster_df,
                            sample_df = ind_centroids,
                            pre_period = c(2, 0, 0),
                            include_start_date = FALSE,
                            post_period = c(0, 0, 0),
                            include_end_date = TRUE,
                            output_directory = "path_to_save_location/ind_climate_2yr_prior.RDS")
```

<br/>

Assign exactly 365 days prior to sampling (for bioclimatic indices, excluding both boundary dates):
```
ind_climate_assigned <- assign_clim.data(
                            grid_df = compiled_clim_raster_df,
                            sample_df = ind_centroids,
                            pre_period = c(1, 0, 1),
                            include_start_date = FALSE,
                            post_period = c(0, 0, 0),
                            include_end_date = FALSE,
                            output_directory = "path_to_save_location/ind_climate_365days.RDS")
```

<br/>

Verify the output after assignment:
```
# Load the saved RDS file
ind_clim_data <- readRDS("path_to_save_location/ind_climate_1yr_prior.RDS")

# Check structure
str(ind_clim_data)

# View first few rows
head(ind_clim_data)

# Check record counts per sample
records_per_sample <- table(ind_clim_data$sample.id)
table(records_per_sample)

# Verify expected number of days
# For 1 year prior, should be 365 or 366 days
summary(records_per_sample)

# Check for any missing climate data
colSums(is.na(ind_clim_data))
```





<br/>

----


<br/>
