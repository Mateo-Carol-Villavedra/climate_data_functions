
# Simplified Functions for Extracting and processing Australian historical daily climate data. 


### Functions to Extract and process Data from SILO, AGCD v.1.0.2 (BOM AWAP) and ANUClimate 2.0 Historical Gridded Datasets:

R Functions developed as part of Carol Villavedra et al. (2022) for extracting and processing gridded historical climate data into bioclimatic indices for individual samples or for reprojection to raster grids. 

<br/>

## If you use these functions, please cite our paper:

#### Carol Villavedra, M., Allen, A.P., Dudaniec, R.Y., O'Hare, J.A. and Beaumont, L.J. (2026). "Historical shifts in wing morphology linked to climate change in the butterfly Tisiphone abeona (Nymphalidae; Satyrinae)." 
<br/>

----

 <br/>
 
# Functions:

|  Function  |  Description :  |  Dependencies:  |
| :--------: |  :------------  | :------------   |
|            |                 |                 |
| `download_AGCD_data` |  Downloads annual files of daily climate data rasters for each user specified year from the AGCD v1.0.2 Database (Previously BOM AWAP), reprojects them to CRS:4326 and crops them to an extent defined by a user supplied shapefile.  |  `curl`, `terra` | 
|            |                 |                 |
| `download_SILO_data` |  Downloads annual files of daily climate data rasters for each user specified year from the SILO Database, reprojects them to CRS:4326 and crops them to an extent defined by a user supplied shapefile.   |  `curl`, `terra` | 
|            |                 |                 |
| `download_ANUCLIM_data` |  Downloads monthly files of daily climate data rasters for each user specified year from the ANUClimate Database, reprojects them to CRS:4326, crops them to an extent defined by a user supplied shapefile and then stacks the monthly rasters into a single annualised raster.   |  `curl`, `terra`, `tidverse`| 
|            |                 |                 |
| `rescale_rasters` |  Rescales ANUClimate 2.0 Gridded data (0.01°x0.01°) to match the resolution of AGCD v1.0.2 and SILO gridded data (0.05°x0.05), if they are to be used simultaneously.   |  `terra`, `tidyverse` | 
|            |                 |                 |
| `make_cell_centroids_df` |  Computes grid cell centroid locations for grid cells or samples to the resolution of the rasters being used.   | `terra`, `sf`, `tidyverse` | 
|            |                 |                 |
| `extract_and_compile_clim.data` |  Extracts climate data for every day in the rasters in question for each location from a set of user supplied centroids, converting all data to a long format dataframe.   |  `sf`, `terra`, `tidyverse`, `data.table` | 
|            |                 |                 |
| `assign_clim.data` |  Assigns climate data from the output of the "extract_and_compile_clim.data" function to each individual based on location and sampling date, with user defined temporal envelopes for each sample.  | `tidyverse`, `data.table` | 
|            |                 |                 |
| `compute_ind_bioclims` |  Computes bioclimatic indices BIO1-BIO27 (See Xu and Hutchinson 2011) for each individual for an annualised set of dates, extracted by the function "assign_clim.data".  | `tidyverse`| 
|            |                 |                 |
| `compute_centroid_bioclims` |  Computes bioclimatic indices for each calendar year at each centroid from the dataframe produced by the "extract_and_compile_clim.data" function, optinoally allowing for the averaging of these values of any time period.   |`tidyverse` | 

<br/>
<br/>

## Dependencies:

### All Dependencies

`curl` <br/>
`terra` <br/>
`sf` <br/>
`tidyverse` <br/>
`data.table` <br/>
  
----

 <br/>

## Available Climate Data:
<br/>

### AGCD v1.0.2 (Australian Gridded Climate Data)
### Previously BOM AWAP (Bureau of Meteorology Australian Water Availability Project)

#### Resolution = 0.05° x 0.05° <br/>

|         Variable              | AGCD Name       | Available From |
|:------------------------------|:---------------:|:--------------:|
| Precipitation                 | precip          |     1900       |
| Maximum Temperature           | tmax            |     1910       |
| Minimum Temperature           | tmin            |     1910       |
| Vapour Pressure (9am / 09:00) | vapourpres_h09  |     1971       |
| Vapour Pressure (3pm / 15:00) | vapourpres_h15  |     1971       |

<br/>
<br/>

### SILO (Scientific Information for Land Owners)

#### Resolution = 0.05° x 0.05° <br/>

|         Variable                                                      | SILO Name       | Available From |
|:----------------------------------------------------------------------|:-------------------:|:--------------:|
| Precipitation                                                         | daily_rain          |     1889       |
| Maximum Temperature                                                   | max_temp            |     1889       |
| Minimum Temperature                                                   | min_temp            |     1889       |
| Solar Radiation (Both Direct and Diffuse Components)                  | radiation           |     1889       |
| Vapour Pressure                                                       | vp                  |     1889       |
| Vapour Pressure Deficit                                               | vp_deficit          |     1889       |
| Class A Pan Evaporation                                               | evap_pan            |     1889       |
| Synthetic Estimate                                                    | evap_syn            |     1889       |
| Combination Estimate (Pre-1970 = Synthetic, Post-1970 = Class A Pan)  | evap_comb           |     1889       |
| Morton Shallow Lake Evaporation                                       | evap_morton_lake    |     1889       |
| Relative Humidity at time of Maximum Daily Temperature                | rh_tmax             |     1889       |
| Relative Humidity at time of Minimum Daily Temperature                | rh_tmin             |     1889       |
| FAO56 Short Crop                                                      | et_short_crop       |     1889       |
| ASCE Tall crop                                                        | et_tall_crop        |     1889       |
| Morton's Areal Actual Evapotranspiration                              | et_morton_actual    |     1889       |
| Mortons Point Potential Evapotranspiration                            | et_morton_potential |     1889       |
| Mortons Wet-Environment Areal Potential Evapotranspiration Over Land  | et_morton_wet       |     1889       |
| Mean Sea Level Pressure                                               | mslp                |     1889       |

<br/>
<br/>

### ANUClimate 2.0

#### Resolution = 0.01° x 0.01°  <br/>

|         Variable        | ANUClimate Name     | Available From |
|:------------------------|:-------------------:|:--------------:|
| Precipitation           | rain                |     1900       |
| Maximum Temperature     | tmax                |     1960       |
| Minimum Temperature     | tmin                |     1960       |
| Average Temperature     | tavg                |     1960       |
| Solar Radiation         | srad                |     1960       |
| Class A Pan Evaporation | evap                |     1970       |
| Vapour Pressure         | vp                  |     1960       |
| Vapour Pressure Deficit | vpd                 |     1960       |

----

 <br/>
 

## Available Bioclimatic Indices: <br/>
  
  <br/>
  
**See Carol Villavedra et al. (2026) Supplementary Materials for Specific Arithmetic used to Compute Each Bioclimatic Index.** 

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

----
 <br/>
 
## User Supplied Data:

In order to use these functions, the user will need to provide the following:

### Shapefile

A polygon shapefile in CRS:4326 which envelops the region for which climate data is to be extracted. 

Used in `download_AGCD_data`, `download_SILO_data` and `download_ANUClim_data` to crop rasters.

      - Can be easily produced in QGIS or other GIS programs:
            - Create a polygon vector layer.
            - Draw a Polygon for the region using the "add polygon feature" tool (QGIS).
            - Ensure that the object is a valid polygon (i.e. no overlapping vertices or borders)
            - Export the layer as a shapefile.

      
      - Be aware of the grid cell resolution when creating your shapefile cropping polygon.

      
      - Ensure that the extent of the polygon has a margin of a grid cell or so from the cells actually needed. 
            - If the border of the polygon overlaps with any cells, it will cause that cell to be NA following cropping.

      
      - The larger the polygon, the larger the raster data files.
            - Larger Files = Increased Computational Load.
            - This effect is compounded by the number of years for which data is collected.


### Sample Metadata / Ind Metadata

A R dataframe object which is used assign samples to a grid cell based on lat lons and to assign climate data to individuals based on grid cell and dates. 

Used in `make_cell_centroids_df` and `assign_clim.data`

      - Requires the following information:
            - sample.id
            - lat (decimal degrees)
            - lon (decimal degrees)
            - date (as dd/mm/yyyy)

----
 <br/>

# Workflow:


### Step 1:

Download and Crop Climate dataset for variables and years of interest

**Functions:** `download_AGCD_data` and/or `download_SILO_data` and/or `download_ANUCLIM_data`
 <br/>

### Step 2:  (OPTIONAL)

If using variable from ANUClim as well as SILO and/or AGCD, rescale ANUClim rasters to match SILO and AGCD

**Functions:** `rescale_rasters`
<br/>


### Step 3:

Generate dataframes of cell centroids according to raster resolution for all grid cells (method = "grid") and samples (method = "sample")  

**Functions:** `make_centroids_df`
 <br/>


### Step 4:

Convert Multi-band Rasters to Long format dataframes, using the processed rasters and the dataframe produced by the `make_centroids_df` function (method = "grid").

**Functions:** `extract_and_compile_clim.data`
 <br/>


### Step 5: 

Assign climate data from the output of `extract_and_compile_clim.data` to individuals based on the location and date in the output of `make_cell_centroids_df` function (method = "sample") and user defined prior and post periods. 

**NOTE:** If downstream workflow includes computing bioclimatic indices for each individual (`compute_ind_bioclims`), ensure the time period for which climate data is assigned to each individual is equal to 1 year (365/366 days)

**Functions:** `assign_clim.data`
 <br/>


### Step 6:

Compute Bioclimatic Indices for samples.

**Functions:** `compute_ind_bioclims`
<br/>


### Step 7: 

Compute Bioclimatix Indices for grid cells to produce spatial grids of indices. 

**Functions:** `compute_centroid_bioclims`


<br/>        


----


## Test Dataset - Modified dataset from Carol Villavedra et al. (2026):

An example dataset to test the functions and their use can be found in this repository under in the folder "test_dataset"

It contains a metadata file which is correctly formatted for the functions as well as an example shapefile to use to crop the climate data rasters. 

Due to the size of the climate data files, examples were not uploaded. 

<br/>

----

## Monthly Climate Data Processing:

The above functions are only implemented for daily climate data. 

The databases do have monthly average climate data available which may be prone to less errors. 

The modification of the above functions to facilitate the use of monthly climate data would require the changing of how the functions are dealing with dates, to shift from daily (i.e. 365 days in a year) to monthly (12 months in a year). 

Furthermore, if the sample date resolution is daily, it may be necessary to produce composite monthly averages for the annualised indices, weighting the relative contribution of days from each month in the composite for months at the edge of year boundaries for each sample. 

This should not be a problem for the annualised gridded bioclimatic indices. 

<br/>

-----


# Contacts:

These functions may have errors or issues or simply we may not have thought of a useful functionality - Please contact us. 

- Mateo Carol Villavedra - mateo.carolvillavedra@mq.edu.au
- Drew Allen - drew.allen@mq.edu.au
