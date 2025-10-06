
#           download_AGCD_clim.data


##                Function Description:               ##
########################################################


# Downloads annual raster grids for daily climate data from the AGCD (previously known as BOM AGCD) climate dataset for user specified years.


# Automatically generates a directory to store downloaded files of each climate variable within the working directory,
            # i.e. user_directory/precip

# Downstream functions in the workflow will work from these directories.

# Generates sub-directories within each variable-specific directory to store different states of the raster (cropped, reprojected, etc.) 


# direct downloads are saved into a sub-directory within the variable directory called "raw"
            # i.e. user_directory/precip/raw



# Re-projects all rasters to CRS:4326 - for compatibility with other data sources.

# Crops rasters using a user supplied shapefile of the region within Australia for which the data is needed. 
      # This greatly reduces computational load downstream. 

# Cropped and re-projected rasters are saved into a sub-directory within the variable directory called "processed"
            # i.e. user_directory/precip/processed


########################################################




##                     User Inputs                    ##
########################################################


#    -    first_year                -  the first year from which to download the data


#...............................................................................................................................................................................


#    -    last_year                 -  the last year from which to download the data


#...............................................................................................................................................................................


#    -    year_interval             -  the interval between years (i.e. 1 = every year, 2 = every second year, 10 = once a decade, etc.)


#...............................................................................................................................................................................


#    -    agcd_clim.var             -  a string of variable names which match those used by BOM AGCD database
                                            # VARIABLES AVAILABLE FROM THE BOM AGCD DATABASE:
                                            #..............................................................................
                                            # Precipitation                    =  "precip"                 From 1900
                                            # Maximum Temperature              =  "tmax"                   From 1910
                                            # Minimum Temperature              =  "tmin"                   From 1910
                                            # Vapour Pressure (9am / 09:00)    =  "vapourpres_h09"         From 1971
                                            # Vapour Pressure (3pm / 15:00)    =  "vapourpres_h15"         From 1971


#...............................................................................................................................................................................


#    -    directory                 -  the file directory to save the downloaded data (formatted as "../folder1/subfolder")
#                                         -  direct downloads will be saved to a subdirectory called "raw"
#                                         -  cropped and reprojected files will be saved to a subdirectory called "processed"


#...............................................................................................................................................................................


#    -    overwrite_download        -  whether or not to to overwrite existing direct downloaded year raster files with new downloads
#                                         -  default = FALSE
#                                         -  If FALSE and the file already exists, 
#                                                           the function will either crop (if the file exists and the "overwrite_crop" option is TRUE)
#                                                            or move onto the next year for that variable. 


#...............................................................................................................................................................................


#    -    crop_shape                -   a Shapefile of a polygon which entirely encompasses the desired region for sampling
#                                                                       used to crop the rasters after downloading to reduce file size. 
#                                         -  User Must ensure that the polygon is valid and in CRS: 4326
#                                         -  In order to preserve all required datapoint, the polygon should have a margin of a few cells from the first cell actually needed
#                                                     as slight mismatches between climate databases with regard to raster extent can cause issues downstream. 


#...............................................................................................................................................................................


#    -    overwrite_download        -  whether or not to to overwrite existing direct downloaded year raster files with new downloads
#                                         -  Default = FALSE
#                                         -  If FALSE and the file already exists, 
#                                                            the function will either crop (if the file exists and the "overwrite_crop" option is TRUE)
#                                                             or move onto the next year for that variable. 
#                                         -  If TRUE, then all downloads will be overwritten with new downloads. 


#...............................................................................................................................................................................


#    -    overwrite_crop            -  whether or not to overwrite existing cropped raster files which new cropped raster files from existing uncropped downloads. 
#                                         -  default = FALSE
#                                         -  If FALSE and the cropped files already exist, then the function will move onto the next
#                                         -  If FALSE but the cropped files don't exist, new cropped files will be produced. 
#                                         -  If TRUE, then all files will be cropped and saved. 


########################################################




##                      Function                      ##
########################################################


download_AGCD_clim.data <- function(first_year,
                                    last_year,
                                    year_interval,
                                    agcd_clim.var,
                                    directory,
                                    crop_shape,
                                    overwrite_download = FALSE,
                                    overwrite_crop = FALSE) {
      
      # Ensuring Packages are Loaded:
      library(curl)
      library(terra)
      
      # Defining the year to iterate the function over to download the required climate data:
      data_years <- seq(from = first_year, to = last_year, by = year_interval)
      
      
      # Check for Function    ----
      
      # Ensuring User Defined first year is not earlier than the first year from which climate data is available from BOM AGCD
      if(first_year < 1900) {
            stop("First Year of Climate Data Available from BOM AGCD = 1900")
            cat("\n")
      }
      
      # Ensuring that the year interval is not less than 1
      if(year_interval < 1) {
            stop("Minimum Year Interval is 1")
            cat("\n")
      }
      
      
      # Ensuring that the first year is not later than the last year:
      if(first_year > last_year) {
            stop("First Year must be at least 1 year prior to last year")
            cat("\n")
      }
      
      
      # If crop_shape is a filepath, read it in
      if (is.character(crop_shape)) {
            if (!file.exists(crop_shape)) {
                  stop("The crop_shape file path does not exist: ", crop_shape)
                  cat("\n")
            }
            crop_shape <- terra::vect(crop_shape)
      } else if (!inherits(crop_shape, c("SpatVector", "SpatRaster"))) {
            stop("crop_shape must be a terra SpatVector, SpatRaster, or a valid file path")
            cat("\n")
      }
      #----
      
      
      
      # VARIABLES AVAILABLE FROM THE BOM AGCD DATABASE:
      # Precipitation                    =  "precip"              From 1900
      # Maximum Temperature              =  "tmax"                From 1910
      # Minimum Temperature              =  "tmin"                From 1910
      # Vapour Pressure (9am / 09:00)    =  "vapourpres_h09"        From 1971
      # Vapour Pressure (3pm / 15:00)    =  "vapourpres_h15"        From 1971
      
      # Checking that the user defined variables match those used by the BOM AGCD database  ----
      # List of acceptable variable names:
      true_var.names <- c("precip", "tmax", "tmin", "vapourpres_h09", "vapourpres_h15")
      
      # Checking that all variables defined by the user are within the list of "true variable names"
      invalid_var.names <- agcd_clim.var[!agcd_clim.var %in% true_var.names]
      
      if(length(invalid_var.names) > 0) {
            # if the user defined variables are not present then the function will stop and force an error:
            stop(paste0("User Selected Variable Names Not Matching to BOM AGCD Names. 
               
               Invalid Variable Names:", paste(invalid_var.names, collapse = ", ")))
            cat("\n")
      }
      #----
      
      
      # Defining the database Central directory:
      AGCD_directory <- "https://thredds.nci.org.au/thredds/fileServer/zv2/agcd/v1-0-2/"
      
      
      # Looping through each variable
      for (var in agcd_clim.var) {  
            
            
            # Creating output folders
            var.output_dir <- paste0(directory, "/", var, "/raw")
            dir.create(var.output_dir, recursive = TRUE, showWarnings = FALSE)
            
            # Output folder for processed (cropped + reprojected) files
            var.processed_dir <- paste0(directory, "/", var, "/processed")
            dir.create(var.processed_dir, recursive = TRUE, showWarnings = FALSE)
            
            
            
            # Defining the repository depending on the climate data:
            # Also defining valid year for each variable      ----
            if(var == "precip") {
                  agcd.data.repo <- paste0(AGCD_directory, "precip/total/r005/01day/")
                  file_prefix <- "agcd_v1_precip_total_r005_daily_"
                  
                  min_year <- 1900
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "tmax") {
                  
                  agcd.data.repo <- paste0(AGCD_directory, "tmax/mean/r005/01day/")
                  file_prefix <- "agcd_v1_tmax_mean_r005_daily_"
                  
                  min_year <- 1910
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "tmin") {
                  
                  agcd.data.repo <- paste0(AGCD_directory, "tmin/mean/r005/01day/")
                  file_prefix <- "agcd_v1_tmin_mean_r005_daily_"
                  
                  min_year <- 1910
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "vapourpres_h09") {
                  
                  agcd.data.repo <- paste0(AGCD_directory, "vapourpres_h09/mean/r005/01day/")
                  file_prefix <- "agcd_v1_vapourpres_h09_mean_r005_daily_"
                  
                  min_year <- 1971
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "vapourpres_h15") {
                  
                  agcd.data.repo <- paste0(AGCD_directory, "vapourpres_h15/mean/r005/01day/")
                  file_prefix <- "agcd_v1_vapourpres_h15_mean_r005_daily_"
                  
                  min_year <- 1971
                  valid_years <- data_years[data_years >= min_year]
            }
            #----
            
            
            
            # printing messages of valid years to be iterated over   ----
            if(length(valid_years) == 0) {
                  message(paste0("No data available for variable: ", var, " for user defined period.
                            First Data Available for ", var, " from ", min_year, "."))
                  cat("\n")
                  
            } else if (length(valid_years) < length(data_years)) {
                  message(paste0("No data available for variable: ", var, " until ", min_year, "
                            First Data Available for ", var, " from ", min_year, "."))
                  cat("\n")
                  
            } else if (length(valid_years) == length(data_years)) {
                  message(paste0("Data available for all user defined years for ", var, "."))
                  cat("\n")
            }
            #----
            
            
            # printing Message of All Files to be Downloaded for this Variable:
            message(paste0("For ", var, ", data to be downloaded for the following years: ", paste(valid_years, collapse = ", ")))
            cat("\n")
            
            # iterating over years and downloading data  ----
            for (i in valid_years) { 
                  
                  # Making a download URL
                  download_url <- paste0(agcd.data.repo, file_prefix, i, ".nc")
                  
                  # Making a filename for each download:
                  output_filename <- paste0(var.output_dir, "/", var, "_", i, "_raw.nc")
                  
                  # Check if full file already exists    ----
                  if(file.exists(output_filename) & !overwrite_download) {
                        message(paste0("Full file already exists for ", i, " (", var, "). Skipping download. Set overwrite=TRUE to re-download."))
                        cat("\n")
                  } else {
                        
                        # Actually Downloading The Files but using a trycatch error handler:
                        tryCatch({
                              curl_download(download_url, output_filename)
                              message(paste0("Data from ", i, " downloaded for ", var, "."))
                              cat("\n")
                              
                        }, error = function(e) {
                              message(paste0("Error downloading data from ", i, " for ", var, ": ", e$message))
                              cat("\n")
                        })
                  }
                  #----
                  
                  
                  # Define cropped + reprojected filenames
                  processed_filename <- file.path(var.processed_dir, paste0(var, "_", i, "_processed.nc"))
                  
                  
                  # Skip processing if crop file already exists and overwrite_crop=FALSE
                  # Skip processing if crop file already exists and overwrite_crop=FALSE
                  if (file.exists(processed_filename) && !overwrite_crop) {
                        message("Using existing cropped file: ", processed_filename)
                        cat("\n")
                  } else {
                        message(">>>> Processing year ", i, " (", var, ")")
                        cat("\n")
                        
                        if (!file.exists(output_filename)) {
                              message("Skipping processing for ", var, " ", i, " because raw file is missing.")
                              cat("\n")
                              next
                        }
                        
                        tryCatch({
                              r <- terra::rast(output_filename)
                              
                              # Reproject first (all AGCD data are EPSG:4283, but standardise to WGS84 EPSG:4326)
                              message("Reprojecting ", var, " ", i, " to WGS84...")
                              cat("\n")
                              r <- terra::project(r, "EPSG:4326")
                              
                              # Crop using user shapefile
                              message("Cropping ", var, " ", i, " to region of interest...")
                              cat("\n")
                              r <- terra::crop(r, crop_shape, mask = TRUE)
                              
                              # Save cropped + reprojected
                              terra::writeCDF(r, filename = processed_filename, varname = var, timename = "time", overwrite = TRUE, compression = 4)
                              
                              message("Finished cropping + reprojecting ", var, " ", i)
                              cat("\n")
                              
                              rm(r)
                              invisible(gc())
                        }, error = function(e) {
                              message("Error processing ", var, " ", i, ": ", e$message)
                              cat("\n")
                        })
                  }
                  
            }
            
            file.remove(list.files(var.output_dir, pattern = "\\.aux$|\\.aux\\.xml$|\\.json$", full.names = TRUE))
      }
      message("\n=== Download Complete ===")
      cat("\n")
}


########################################################




##                   Example Syntax:                  ##
########################################################


# download_SILO_clim.data(first_year = 2019,
#                         last_year = 2020,
#                         year_interval = 1,
#                         silo_clim.var = c("tmin", "tmax"),
#                         directory = "github/clim_data",
#                         crop_shape = "github/region_shapefile/Raster_Crop_Extent.shp",
#                         overwrite_download = FALSE,
#                         overwrite_crop = TRUE)


########################################################