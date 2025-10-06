
# Simplified Functions for Extracting and processing historical climate data. 


### Functions to Extract and process Data from SILO, AGCD (BOM AWAP) and ANUClimate 2.0 Historical Gridded Datasets:

R Functions developed as part of Carol Villavedra et al. (2022) for extracting and processing gridded historical climate data into bioclimatic indices for individual samples or for reprojection to raster grids. 



### If you use these functions, please cite our paper:

Carol Villavedra, et al. (2026). Historical shifts in wing morphology linked to climate change in the butterfly Tisphone abeona (Nymphalidae; Satyrinae). 



## Functions:

1 - **download_AGCD_data** - Downloads annual files of daily climate data rasters for each user specified year from the AGCD Database (Previously BOM AWAP), reprojects them to CRS:4326 and crops them to an extent defined by a user supplied shapefile. 

2 - **download_SILO_data** - Downloads annual files of daily climate data rasters for each user specified year from the SILO Database, reprojects them to CRS:4326 and crops them to an extent defined by a user supplied shapefile. 

3 - **download_ANUClim_data** - Downloads monthly files of daily climate data rasters for each user specified year from the ANUClimate Database, reprojects them to CRS:4326, crops them to an extent defined by a user supplied shapefile and then stacks the monthly rasters into a single annualised raster. 

4 - **rescale_rasters** - Rescales ANUClimate 2.0 Gridded data to match the resolution of AGCD and SILO gridded data, if they are to be used simultaneously. 

5 - **make_cel_centroids_df** - Computes grid cell centroid locations for grid cells or samples to the resolution of the rasters being used. 

6 - **extract_and_compile_clim.data** - Extracts climate data for every day in the rasters in question for each location from a set of user supplied centroids, converting all data to a long format dataframe. 

7 - **assign_clim.data** - Assigns climate data from the output of the "extract_and_compile_clim.data" function to each individual based on location and sampling date, with user defined temporal envelopes for each sample. 

8 - **compute_ind_bioclims** - Computes bioclimatic indices BIO1-BIO27 (See Xu and Hutchinson 2011) for each individual for an annualised set of dates, extracted by the function "assign_clim.data".

9 - **compute_centroid_bioclims** - Computes bioclimatic indices for each calendar year at each centroid from the dataframe produced by the "extract_and_compile_clim.data" function, optinoally allowing for the averaging of these values of any time period. 




## Dependencies:

### All Dependencies

curl
terra
sf
tidyverse
data.table


### Function Specific Dependencies

**download_AWAP_data**: curl, terra

**download_SILO_data**: curl, terra

**download_ANUCLIM_data**: curl, terra, lubridate

**rescale_rasters**: terra, tidyverse

**make_cell_centroids_df**: terra, sf, tidyverse

**extract_and_compile_clim.data**: sf, terra, tidyverse, data.table

**assign_clim.data**: tidyverse, data.table

**compute_ind_bioclims**: tidyverse

**compute_centroid_bioclims**: tidyverse



## User Supplied Data:

In order to use these functions, the user will need to provide the following:

### Shapefile

A polygon shapefile in CRS:4326 which envelops the region for which climate data is to be extracted. 

Used in **download_AGCD_data**, **download_SILO_data** and **download_ANUClim_data** to crop rasters.

      - Can be easily produced in QGIS or other GIS programs by creating a polygon vector layer, drawing the region for which climate data is needed and exporting the layer as a shapefile. 
      
      - Ensure that the object is a valid polygon (i.e. no overlapping vertices or borders) or the function will likely cause an error. 
      
      - Be aware of the grid cell resolution when creating your shapefile cropping polygon. 
      
      - Ensure that the extent of the polygon has a margin of a grid cell or so from the cells actually needed as if the border of the polygon overlaps with any cells, it will cause that cell to be NA following cropping. 
      
      - However, the larger the polygon, the larger the raster data files and the higher the computational load of the functions, particularly with a high number of years. 


### Sample Metadata / Ind Metadata

A R dataframe object which is used assign samples to a grid cell based on lat lons and to assign climate data to individuals based on grid cell and dates. 

Used in **make_cell_centroids_df** and **assign_clim.data**

      - Requires the following information:
            - sample.id
            - latitude (decimal degrees)
            - longitude (decimal degrees)
            - date (as dd/mm/yyyy)



## Workflow:


### Step 1:

Download and Crop Climate dataset for year of interest
            Functions: **download_AWAP_data**, **download_SILO_data** and/or **download_ANUCLIM_data**


### Step 2:

Rescale ANUClim rasters to match SILO and AGCD - **NOTE:** only necessary if using ANUClim and SILO/AGCD data alongside one another)
            Functions: **rescale_rasters**


### Step 3:

Generate dataframes of cell centroids according to raster resolution for all grid cells (method = "grid") and samples (method = "sample")
            Functions: **make_centroids_df**


### Step 4:

Convert Multi-band Rasters to Long format dataframes, using the processed rasters and the dataframe produced by the **make_centroids_df** function (method = "grid").
            Functions: **extract_and_compile_clim.data**


### Step 5: 

Assign climate data to individuals based on the location and date in the output of **make_cell_centroids_df** function and user defined prior and post periods. 
            Functions: **assign_clim.data**

**NOTE:** If downstream workflow includes computing bioclimatic indices for each individual, ensure the time period for which climate data is assigned to each individual is equal to 1 year (365/366 days)


### Step 6:

Compute Bioclimatic Indices for samples.
            Functions: **compute_ind_bioclims**


### Step 7: 

Compute Bioclimatix Indices for grid cells to produce spatial grids of indices. 
            Functions: **compute_centroid_bioclims**
            




## Test Dataset - Modified dataset from Carol Villavedra et al. (2026):

An example dataset to test the functions and their use can be found in this repository under in the folder "test_dataset"

It contains a metadata file which is correctly formatted for the functions as well as 






### Contact:

These functions may have errors or issues or simply we may not have thought of a useful functionality - Please contact us. 

- Mateo Carol Villavedra - mateo.carolvillavedra@mq.edu.au
- Drew Allen - drew.allen@mq.edu.au