
#           download_ANUClim_clim.data


##                Function Description:               ##
########################################################


# Downloads monthly raster grids for daily climate data from the ANUclimate dataset for user specified years.


# Automatically generates a directory to store downloaded files of each climate variable within the working directory,
# i.e. user_directory/rain

# Downstream functions in the workflow will work from these directories.

# Generates sub-directories within each variable-specific directory to store different states of the raster (cropped, reprojected, etc.) 


# direct downloads (monthly) are saved into a sub-directory within the variable directory called "monthly"
# i.e. user_directory/rain/monthly



# Re-projects all monthly rasters to CRS:4326 - for compatibility with other data sources.

# Crops rasters using a user supplied shapefile of the region within Australia for which the data is needed. 
# This greatly reduces computational load downstream. 

# Cropped and re-projected monthly rasters are saved into a sub-directory within the variable directory called "monthly_cropped"
# i.e. user_directory/rain/monthly_cropped



# Monthly cropped files are then stacked into a single annual Raster per year (preserving dates) for compatibility with other data sources. 

# Annual stacked rasters are then saved into a sub-directory within the variable directory called "processed"
#           i.e. user_directory/rain/processed



# Since Temperature variables from AGCD and ANUClim are named the same way (tmin, tmax), the function renames the ANUClim versions:
            # tmin becomes t_min
            # tmax becomes t_max


########################################################




##                     User Inputs                    ##
########################################################


#    -    first_year                -  the first year from which to download the data


#...............................................................................................................................................................................


#    -    last_year                 -  the last year from which to download the data


#...............................................................................................................................................................................


#    -    year_interval             -  the interval between years (i.e. 1 = every year, 2 = every second year, 10 = once a decade, etc.)


#...............................................................................................................................................................................


#    -    anuclim_clim.var          -  a string of variable names which match those used by SILO database
                                                # VARIABLES AVAILABLE FROM THE ANUCLIM DATABASE:
                                                #..............................................................................
                                                # Class A Pan Evaporation          =  "evap"               From 1970
                                                # Precipitation                    =  "rain"               From 1900
                                                # Radiation                        =  "srad"               From 1960
                                                # Average Temperature              =  "tavg"               From 1960
                                                # Maximum Temperature              =  "tmax"               From 1960
                                                # Minimum Temperature              =  "tmin"               From 1960
                                                # Vapour Pressure                  =  "vp"                 From 1960
                                                # Vapour Pressure Deficit          =  "vpd"                From 1960


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


#    -    overwrite_crop            -  whether or not to overwrite existing cropped raster files with new cropped raster files from existing unprocessed downloads. 
#                                         -  default = FALSE
#                                         -  If FALSE and the cropped files already exist, then the function will move onto the next
#                                         -  If FALSE but the cropped files don't exist, new cropped files will be produced. 
#                                         -  If TRUE, then all files will be cropped and saved. 


#...............................................................................................................................................................................


#    -    overwrite_compile         -  whether or not to overwrite existing compiled annual raster files with new cropped raster files from existing processed monthly files
#                                         -  default = FALSE
#                                         -  If FALSE and the annualized processed file already exist, then the function will move onto the next
#                                         -  If FALSE but the annualized processed file don't exist, processed monthly files for that year will be compiled to an annual file
#                                         -  If TRUE, then all monthly files will be compiled to annualised files. 


########################################################




##                      Function                      ##
########################################################


download_ANUClim_clim.data <- function(first_year,
                                       last_year,
                                       year_interval, 
                                       anuclim_clim.var,
                                       directory,
                                       crop_shape,
                                       overwrite_download = FALSE,
                                       overwrite_crop = FALSE,
                                       overwrite_compile = FALSE) {
      
      # Ensuring Packages are Loaded:
      library(curl)
      library(terra)
      library(lubridate)
      
      
      # Defining the year to iterate the function over to download the required climate data:
      data_years <- seq(from = first_year, to = last_year, by = year_interval)
      
      
      # Check for Function    ----
      
      # Ensuring User Defined first year is not earlier than the first year from which climate data is available from ANUCLIM
      if(first_year < 1900) {
            stop("First Year of Climate Data Available from ANUCLIM = 1900")
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
      
      
      # VARIABLES AVAILABLE FROM THE ANUCLIM DATABASE:
      # Class A Pan Evaporation          =  "evap"               From 1970
      # Precipitation                    =  "rain"               From 1900
      # Radiation                        =  "srad"               From 1960
      # Average Temperature              =  "tavg"               From 1960
      # Maximum Temperature              =  "tmax"               From 1960
      # Minimum Temperature              =  "tmin"               From 1960
      # Vapour Pressure                  =  "vp"                 From 1960
      # Vapour Pressure Deficit          =  "vpd"                From 1960
      
      # Checking that the user defined variables match those used by the ANUCLIM database  ----
      # List of acceptable variable names:
      true_var.names <- c("evap", "rain", "srad", "tavg", "tmax", "tmin", "vp", "vpd")
      
      # Checking that all variables defined by the user are within the list of "true variable names"
      invalid_var.names <- anuclim_clim.var[!anuclim_clim.var %in% true_var.names]
      
      if(length(invalid_var.names) > 0) {
            # if the user defined variables are not present then the function will stop and force an error:
            stop(paste0("User Selected Variable Names Not Matching to ANUCLIM Names. 
               
               Invalid Variable Names:", paste(invalid_var.names, collapse = ", ")))
      }
      #----
      
      
      # Defining the database Central directory:
      ANUCLIM_directory <- "https://thredds.nci.org.au/thredds/fileServer/gh70/ANUClimate/v2-0/stable/day/"
      
      
      # Looping through each variable
      for (var in anuclim_clim.var) {  
            
            # Renaming tmin and tmax to avoid overlaps with the AWAP dataset:
            if (var == "tmin") {
                  out_var <- "t_min"
            } else if (var == "tmax") {
                  out_var <- "t_max"
            } else {
                  out_var <- var
            }
            
            
            
            
            # Creating output folders for each of the selected variables. ----
            var.monthly_dir <- paste0(directory, "/", out_var, "/monthly")
            var.processed_dir <- paste0(directory, "/", out_var, "/processed")
            dir.create(var.monthly_dir, recursive = TRUE, showWarnings = FALSE)
            dir.create(var.processed_dir, recursive = TRUE, showWarnings = FALSE)
            # Create folder for processed monthly rasters
            var.monthly_processed_dir <- file.path(directory, out_var, "monthly_processed")
            dir.create(var.monthly_processed_dir, recursive = TRUE, showWarnings = FALSE)
            #----
            
            
            
            
            
            # Defining the repository depending on the climate data:
            # Also defining valid year for each variable      ----
            if(var == "evap") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1970
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "rain") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1900
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "srad") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1960
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "tavg") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1960
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "tmax") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1960
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "tmin") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1960
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "vp") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1960
                  valid_years <- data_years[data_years >= min_year]
                  
            } else if (var == "vpd") {
                  
                  anuclim.data.repo <- paste0(ANUCLIM_directory, var, "/")
                  file_prefix <- paste0("ANUClimate_v2-0_", var, "_daily_")
                  
                  min_year <- 1960
                  valid_years <- data_years[data_years >= min_year]
            }
            #----
            
            
            
            # printing messages of valid years to be iterated over   ----
            if(length(valid_years) == 0) {
                  print(paste0("No data available for variable: ", out_var, " for user defined period.
                            First Data Available for ", out_var, " from ", min_year, "."))
                  cat("\n")
                  
            } else if (length(valid_years) < length(data_years)) {
                  print(paste0("No data available for variable: ", out_var, " until ", min_year, "
                            First Data Available for ", out_var, " from ", min_year, "."))
                  cat("\n")
                  
            } else if (length(valid_years) == length(data_years)) {
                  print(paste0("Data available for all user defined years for ", out_var, "."))
                  cat("\n")
            }
            #----
            
            
            # printing Message of All Files to be Downloaded for this Variable:
            message(paste0("For ", out_var, ", data to be downloaded for the following years: ", paste(valid_years, collapse = ", ")))
            cat("\n")
            
            # iterating over years and downloading data  ----
            for (i in valid_years) { 
                  
                  
                  
                  # Defining the output filename for the final file:
                  output_filename <- paste0(var.processed_dir, "/", out_var, "_", i, "_processed.nc")
                  
                  
                  # Check if we should skip this entire year
                  skip_year <- file.exists(output_filename) & !overwrite_compile
                  
                  if(skip_year) {
                        message(paste0("Annual file already exists for ", i, " (", out_var, "). Skipping year. Set overwrite_compile=TRUE to re-process."))
                        cat("\n")
                  }
                  
                  
                  # if we are not skipping the year
                  if(!skip_year) { 
                        
                        # Looping through the months for each year   ----
                        for (month in 1:12) {
                              
                              # Format month with leading zero
                              month_str <- sprintf("%02d", month)
                              
                              # Making a download URL for this month
                              download_url <- paste0(anuclim.data.repo, i, "/", file_prefix, i, month_str, ".nc")
                              
                              
                              # Making a filename for this monthly download
                              monthly_filename <- paste0(var.monthly_dir, "/", out_var, "_", i, "_", month_str, "_monthly.nc")
                              
                              
                              # Check if full file already exists    ----
                              if(file.exists(monthly_filename) & !overwrite_download) {
                                    message(paste0("Monthly file already exists for month: ", month_str, " of year: ", i, " (", out_var, "). Skipping download.", "\n",
                                                   "Set overwrite_download = TRUE to re-download."))
                                    cat("\n")
                              } else {
                                    # Actually Downloading The Files but using a trycatch error handler:
                                    tryCatch({
                                          print(paste0("Downloading:  Month = ", month_str, "  |  Year = ", i, "  |  Var = ", var))
                                          curl_download(download_url, monthly_filename)
                                          message(paste0("Month ", month_str, " of ", i, " downloaded for ", out_var, "."))
                                          cat("\n")
                                          
                                    }, error = function(e) {
                                          message(paste0("Error downloading month ", month_str, " of ", i, " for ", out_var, ": ", e$message))
                                          cat("\n")
                                    })
                              } # End of Monthly file conditional check - for the sub-files from ANUCLIM - for monthly data
                              
                              
                        } # End of Loop through months
                  } # End of Full File conditional check - for the compiled "FULL" raster   
                  
                  #----
                  
                  
                  # Merging All monthly files into a single Raster file     ----
                  if(!skip_year) {
                        tryCatch({
                              
                              # List all monthly files for this year
                              monthly_files <- list.files(var.monthly_dir,
                                                          pattern = paste0(out_var, "_", i, "_\\d{2}_monthly\\.nc"),
                                                          full.names = TRUE)
                              monthly_files <- sort(monthly_files)   # ensure 01,02,...12 ordering
                              
                              # Guard: ensure exactly 12 files exist and they are unique
                              monthly_files <- unique(monthly_files)
                              if (length(monthly_files) != 12) {
                                    message("Found ", length(monthly_files), " monthly files for ", i, " (", out_var, "). Expected 12. Skipping compile.")
                                    cat("\n")
                                    next   # continue to next year
                              }
                              
                              if(length(monthly_files) == 12) {
                                    
                                    
                                    # For each month, get expected days
                                    days_in_month <- if(leap_year(i)) c(31,29,31,30,31,30,31,31,30,31,30,31) else c(31,28,31,30,31,30,31,31,30,31,30,31)
                                    
                                    for(m in 1:12){
                                          r <- terra::rast(monthly_files[m])
                                          if(nlyr(r) != days_in_month[m]){
                                                warning(paste0("Month ", sprintf("%02d", m), " of year ", i, " has ", nlyr(r), 
                                                               " layers, expected ", days_in_month[m], ". Skipping this year."))
                                                cat("\n")
                                                next_year_flag <- TRUE
                                                break
                                          }
                                    }
                                    if(exists("next_year_flag") && next_year_flag) { rm(next_year_flag); next }
                                    
                                    
                                    # Creating a stack of rasters
                                    monthly_stacks <- lapply(monthly_files, function(f) {
                                          
                                          # Define processed file path
                                          processed_file <- file.path(var.monthly_processed_dir, basename(gsub("_monthly\\.nc$", "_processed_month.nc", f)))
                                          
                                          # If processed file exists and overwrite_crop = FALSE, use it
                                          if(file.exists(processed_file) && !overwrite_crop) {
                                                r <- terra::rast(processed_file)
                                                message(paste0("Using existing processed file: ", basename(processed_file)))
                                          } else {
                                                # Otherwise, read original monthly file and crop
                                                r <- terra::rast(f)
                                                
                                                # Crop and mask using the shapefile
                                                if(!same.crs(r, crop_shape)) {
                                                      shape_reproj <- project(crop_shape, crs(r))
                                                } else {
                                                      shape_reproj <- crop_shape
                                                }
                                                
                                                r <- crop(r, shape_reproj)
                                                r <- mask(r, shape_reproj)
                                                
                                                # Save processed raster
                                                writeRaster(r, processed_file, overwrite = TRUE)
                                                message(paste0("Created new processed file: ", basename(processed_file)))
                                          }
                                          
                                          return(r)
                                    })
                                    annual_stack <- do.call(c, monthly_stacks)
                                    
                                    # optional: simple message instead of pb
                                    message("Loaded ", length(monthly_files), " monthly files for ", i, " (", out_var, ")")
                                    cat("\n")
                                    
                                    
                                    # Extracting day information from rasters and verifying it
                                    start_date <- as.Date(paste0(i, "-01-01"))
                                    n_days_expected <- ifelse(leap_year(i), 366, 365)
                                    n_days_actual <- terra::nlyr(annual_stack)
                                    
                                    # Verify layer count matches expected days
                                    if(n_days_actual != n_days_expected) {
                                          warning(paste0("Layer count mismatch for ", i, " (", out_var, "): expected ", n_days_expected, ", got ", n_days_actual))
                                          cat("\n")
                                    }
                                    
                                    # Creating a sequence of dates based on ACTUAL layer count
                                    date_seq <- seq.Date(from = start_date, by = "day", length.out = n_days_actual)
                                    
                                    if(length(date_seq) == n_days_actual) {
                                          names(annual_stack) <- as.character(date_seq)
                                          terra::time(annual_stack) <- date_seq
                                    } else {
                                          warning("Cannot assign names to annual stack: layer count mismatch.")
                                          cat("\n")
                                          next
                                    }
                                    
                                    
                                    # Renaming tmin and tmax to avoid overlaps with the AWAP dataset:
                                    if (var == "tmin") {
                                          message("ANUCLIM climate variable: 'tmin' has been renamed to 't_min' to avoid conflicts with 'tmin' from BOM AWAP Climate Data")
                                          cat("\n")
                                    } else if (var == "tmax") {
                                          message("ANUCLIM climate variable: 'tmax' has been renamed to 't_max' to avoid conflicts with 'tmax' from BOM AWAP Climate Data")
                                          cat("\n")
                                    }
                                    
                                    # Save as single annual NetCDF file
                                    output_filename <- paste0(var.processed_dir, "/", out_var, "_", i, "_processed.nc")
                                    
                                    message(">>>> Projecting Raster to WGS84 (EPSG:4326")
                                    annual_stack <- terra::project(annual_stack, "EPSG:4326")
                                    
                                    message(">>>> Starting writeCDF for ", out_var, " ", i)
                                    terra::writeCDF(annual_stack, filename = output_filename, varname = out_var, timename = "time", overwrite = overwrite_compile, compression = 4)
                                    message(">>>> Finished writeCDF for ", out_var, " ", i)
                                    message(paste0("Annual file for ", i, " created for ", out_var, " (", terra::nlyr(annual_stack), " days)."))
                                    
                                    # Clean up but avoid forcing a long synchronous gc() immediately after write
                                    rm(annual_stack, monthly_files)
                                    # close general R connections (not terra-specific, but helpful)
                                    try(closeAllConnections(), silent = TRUE)
                                    # call gc but keep messages minimal — this usually frees netcdf handles
                                    invisible(gc())
                                    
                                    message("Cleaned up objects and freed memory for ", out_var, " ", i)
                                    cat("\n")
                                    
                              } else {
                                    message(paste0("Warning: Only ", length(monthly_files), " of 12 months downloaded for ", i, " (", out_var, "). Annual file not created."))
                                    cat("\n")
                              }
                              
                        }, error = function(e) {
                              message(paste0("Error merging monthly files for ", i, " (", out_var, "): ", e$message))
                              cat("\n")
                        })
                        
                  }
                  
            } # End of Loop through Years
            
            file.remove(list.files(var.processed_dir, pattern="\\.aux$|\\.aux\\.xml$|\\.json$", full.names=TRUE))
            
      } #End of Loop through variables
      message("\n=== Download Complete ===")
      
}


########################################################




##                   Example Syntax:                  ##
########################################################


# download_ANUClim_clim.data(first_year = 2019,
#                            last_year = 2020,
#                            year_interval = 1,
#                            anuclim_clim.var = c("tmin", "tmax"),
#                            directory = "github/clim_data",
#                            crop_shape = "github/region_shapefile/Raster_Crop_Extent.shp",
#                            overwrite_download = FALSE,
#                            overwrite_compile = T,
#                            overwrite_crop = T)


########################################################
