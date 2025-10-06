
#           make_cell_centroids_df


##                Function Description:               ##
########################################################


# Produces dataframes of cell centroids for the cropped region of defined by the user to be used in downstream workflow. 

# Can be used to compute the centroid locations for all cells in the raster (method = grid)

# Can be used to compute the centroid coordinates for samples - i.e. rounding individual lat lons to the appropriate resolution. 


########################################################




##                     User Inputs                    ##
########################################################


#    -    template                  -  A single example raster from which the centroids will be computed to the right resolution


#...............................................................................................................................................................................


#    -    sample_df                 -  a dataframe of samples for which the climate data is to be collected. 
#                                         -  Each row should be a unique sample and sample ID  
#                                         -  Must contain the following collumns, named as described:
#                                                -  sample.id    - Sample ID for each sample
#                                                -  lat          - latitude for each sample (rounded to match the target resolution)
#                                                -  lon          - longitude for each sample (rounded to match the target resolution)
#                                         -  Example sample_df:
# 'data.frame':	428 obs. of  14 variables:
#  $ sample.id     : chr  "ANIC-14" "ANIC-16" "ANIC-17" "ANIC-18" ...
#  $ sample_no     : int  14 16 17 18 20 21 22 23 24 25 ...
#  $ lat           : num  -35.6 -35.6 -35.1 -35.7 -35.7 ...
#  $ lon           : num  150 150 150 150 150 ...


#...............................................................................................................................................................................


#    -    method                    -  A character string to determine the method for the function:
#                                         -  "grid"  =  Extracts every centroid for the entire cropped sampling region
#                                         -  "sample"  =  Extracts centroids for the grid cells for which samples are found. 


#...............................................................................................................................................................................


#    -    directory                 -  the directory in which to save the file - file named automatically by the function based on resolution and method. 
#                                         - File saved as a .csv file 


########################################################




##                      Function                      ##
########################################################


make_cell_centroids_df <- function(template = NULL,
                                   sample_df = NULL,
                                   method = "grid",
                                   directory) {
      
      # Loading Required Packages:
      library(terra)
      library(sf)
      library(tidyverse)
      
      # Function if the user is converting a grid to centroids based on the shapefile;
      if(method == "grid") {
            
            
            if(is.null(template)) {
                  stop("Template Raster Required for Method = Grid ")
            }
            
            # Load in the template raster - Band 1:
            template_rast <- terra::rast(template)
            
            # getting the resolution of the template:
            resolution <- res(template_rast)[1]
            
            
            # Converting each cell to a centroid point
            pts <- as.data.frame(template_rast[[1]], xy = TRUE, na.rm = TRUE)
            
            # Assigning a centroid ID
            centroids_df <- data.frame(centroid.id = 1:nrow(pts), lat = pts$y, lon = pts$x)
            
            # Saving the Object and Returning it to the user:
            write.csv(centroids_df, paste0(directory, "/region.grid_centroids_res=", resolution, ".csv"))
            return(centroids_df)  
            
            
      } else if(method == "sample") {
            
            if(is.null(template)) {
                  stop("Template Raster Required for Method = Sample ")
            }
            
            
            if(is.null(sample_df)) {
                  stop("Sample Locations Required for Method = Sample")
            }
            
            
            # Load in the template raster - Band 1:
            template_rast <- terra::rast(template)
            
            # getting the resolution of the template:
            resolution <- res(template_rast)[1]
            
            
            centroids_df <- sample_df %>%
                  rename(raw_lat = lat, 
                         raw_lon = lon)
            mutate(lon = round(raw_lat / resolution) * resolution,
                   lat = round(raw_lat / resolution) * resolution) %>%
                  distinct(lat, lon) %>%
                  mutate(centroid.id = row_number())
            
            # Saving the Object and Returning it to the user:
            write.csv(centroids_df, paste0(directory, "/sample_centroids_res=", resolution, ".csv"))
            return(centroids_df)  
            
      } else {
            stop("Method must be 'grid' or 'sample'")
      }
}


########################################################




##                   Example Syntax:                  ##
########################################################


# ind_meta <- read.csv("github/Example_metadata.csv")
# 
# 
# test.centroids_grid <- make_cell_centroids_df(template = "github/clim_data/daily_rain/processed/daily_rain_2019_processed.nc",
#                                               sample_df = ind_meta,
#                                               method = "grid",
#                                               directory = "github/clim_data")


########################################################