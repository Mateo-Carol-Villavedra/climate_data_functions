
# assign_clim.data



##  Description. 

A function to assign climate data for a certain, relevant period to each individual based on their location. This function extracts the data for each individual from the long-format dataframe produced as the output of the `extract_and_compile_clim.data`. <br/>

Each individual is mapped to a grid cell based on latitude and longitude which should be rounded to match the resolution of the source raster, which can be completed using the `make_centroids_df` function, with setting "`method = "sample"`.

Each individual in the input `sample_df` is assigned daily climate data from the relevant grid cell for every day from a user specified time periods (in days) before and after the date associated with each sample. 

This results in each individual accumulating `d` rows where `d` is the number of days in the user specified period.

The resulting dataframe will have, `nrow = d x nrow(sample_df)`, with the climate data for all selected variables for each day assigned to each sample.

<br/>

----


## Function Arguments and Input

### grid_df: <br/>
The R dataframe output of the function `extract_and_compile_clim.data` or an R dataframe with identical characteristics. <br/>
Source from which climate data is extracted and assigned to each individual. <br/>
<br/>


### sample_df: <br/>
The output of the function `make_centroids_df` using `method = "sample"` or an R dataframe with identical characteristics. <br/>
Metadata used to assign individuals to grid cells and to then assign climate data based on sampling date. <br/>
<br/>


### pre_period: <br/>
A numerical vector specifying the number of years, months and days prior to the sampling date should be included in the climate data collected for each sample. <br/>
Formatted as `c(years, months, days)`. <br/>
<br/>


### include_start_date: <br/>
A Logical option which determines whether or not the date on the border of the pre_period is included in the relevant period. <br/>
<br/>


### post_period: <br/>
A numerical vector specifying the number of years, months and days after the sampling date should be included in the climate data collected for each sample. <br/>
Formatted as `c(years, months, days)`. <br/>
<br/>


### include_end_date: <br/>
A Logical option which determines whether or not the date on the border of the pre_period is included in the relevant period. <br/>
<br/>


### output_directory: <br/>
A filepath to save the output of the function as an RDS (include extension). <br/>

<br/>

----


## Output

Each individual in the input `sample_df` is assigned daily climate data from the relevant grid cell for every day from a user specified time periods (in days) before and after the date associated with each sample. 

This results in each individual accumulating `d` rows where `d` is the number of days in the user specified period.

The resulting dataframe will have, `nrow = d x nrow(sample_df)`, with the climate data for all selected variables for each day assigned to each sample.

The resulting dataframe is returned to the user and saved as an `.RDS` file at the filepath specified by the argument; `output_directory`. 

<br/>

----


## Notes:

Make sure to check after running it that the individuals each have the correct number of days based on your needs. You may need to play around with the date controls to find the perfect setting. 



<br/>

----




## Usage Examples:

Insert description Here:

First Load the function from the location where it was downloaded from this repo:
```
source("wd/function_script_path/assign_clim.data.R"
```

<br/>

Then load the output from the `extract_and_compile_clim.data` function:
```
compiled_clim_raster_df <- readRDS("path_to_output_df/output_df_filename.RDS")
```

<br/>

Then load in the dataframe output from the `make_centroids_df` function, using `method = "sample"`:
```
ind_centroids <- read.csv("path_to_ind.centroids_df/ind.centroids_df_filename.csv")
```

<br/>

Now run the function deciding for what time period before and afer sampling date climate data should be collected:
```
# test_assign_clim.data <- assign_clim.data(grid_df = compiled_clim_raster_df,
                                              sample_df = ind_centroids,
                                              pre_period = c(1,0,0),
                                              include_start_date = FALSE,
                                              post_period = c(0,0,0), 
                                              include_end_date = TRUE,
                                              output_directory = "path_to_save_location/Align_Inds_clim.data.RDS")
```





<br/>

----


<br/>
