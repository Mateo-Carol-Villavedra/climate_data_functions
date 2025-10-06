
#           extract_and_compile_clim.data


##                Function Description:               ##
########################################################


# Processes rasters from previous functions, extracting climate data for every date for user specified locations
      # Locations supplied through a dataframe of grid centroids.

# extracts data for each grid cell and day, converting it to a long format dataframe where:
      # each location has 'z' number of rows, where  
            # 'z' is the number of days included in the rasters provided (years x 365 or 366)


# Errors may arise here is the user specified shapefile used to crop the rasters earlier in the workflow are too small.
      # Results in the exclusion of cells which align with centroids. 
      # This error results in many NA values - ensure that the shapefile used earlier encompasses slightly more cells than is necessary. 


########################################################




##                     User Inputs                    ##
########################################################


#    -    first_year                -  the first year from which to download the data


#...............................................................................................................................................................................


#    -    var_directories           -  a vector to the variable sub-directories which are to be computed from raster to dataframe format


#...............................................................................................................................................................................


#    -    centroid_df               -    the output of the make_cell_centroids_df using method = "grid"

#                                         - Users can use a dataframe produced separately but it must adhere to the below:

#                                         -  NOTE THAT THE coordinates of the centroids MUST be rounded to match the resolution of the rasters being used:
#                                                     - IF using BOM/SILO/Rescaled ANUClim  -  0.05 x 0.05
#                                                     - IF using original resolution ANUClim ONLY  -  0.01 x 0.01

#                                         -  Coordinates to be in CRS 4326 and as decimal degrees

#                                         -  Collumns for coordinates should be named as "lat" and "lon"

#                                         -  Each location should be accompanied with a unique identifier number, with collumn name "centroid_id"

                                                # Example dataframe:
                                                #......................
                                                #        lat      lon    centroid_id
                                                # 1   -35.00   150.40              1
                                                # 2   -35.00   150.45              2
                                                # 3   -35.00   150.50              3
                                                # 4   -35.00   150.55              4
                                                # 5   -35.00   150.60              5


#...............................................................................................................................................................................


#    -    output_filepath           -  a path to save the output dataframe as an RDS file (.RDS)


#...............................................................................................................................................................................


#    -    check_crs                 -  if TRUE, checks CRS compatibility and issues warnings


########################################################




##                      Function                      ##
########################################################


extract_and_compile_clim.data <- function(var_directories,  centroid_df, output_filepath, check_crs = TRUE) {
      
      # Ensuring all required packages are loaded:
      library(sf)
      library(terra)
      library(tidyverse)
      library(lubridate)
      library(data.table)
      
      
      # Checking user inputs are valid    ----
      
      # Validate centroid_df structure
      required_cols <- c("lat", "lon", "centroid.id")
      missing_cols <- required_cols[!required_cols %in% names(centroid_df)]
      
      if(length(missing_cols) > 0) {
            stop(paste0("centroid_df missing required columns: ", paste(missing_cols, collapse = ", ")))
      }
      
      # Check that coordinates are numeric
      if(!is.numeric(centroid_df$lat) | !is.numeric(centroid_df$lon)) {
            stop("lat and lon columns must be numeric")
      }
      
      # Check coordinate ranges (should be within Australia roughly)
      if(any(centroid_df$lat < -45 | centroid_df$lat > -10)) {
            warning("Some latitude values outside typical Australian range (-45 to -10)")
      }
      if(any(centroid_df$lon < 110 | centroid_df$lon > 155)) {
            warning("Some longitude values outside typical Australian range (110 to 155)")
      }
      
      # Check that directories exist
      for(dir in var_directories) {
            if(!dir.exists(dir)) {
                  stop(paste0("Directory does not exist: ", dir))
            }
      }
      
      # Create output directory if needed
      output_dir <- dirname(output_filepath)
      if(!dir.exists(output_dir)) {
            dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
      }
      
      message(paste0("Processing ", length(var_directories), " climate variables"))
      message(paste0("Extracting data for ", nrow(centroid_df), " locations"))
      #----
      
      
      
      # Prepare spatial points for extraction ----
      centroids_sf <- st_as_sf(centroid_df, coords = c("lon", "lat"), crs = 4326)
      
      # Store original coordinates as data.table for fast binding
      cent_coords_dt <- data.table( lat = centroid_df$lat, lon = centroid_df$lon, centroid.id = centroid_df$centroid.id )
      #----
      
      
      # Initialize storage for compiled data    ----
      compiled_var_list <- list()
      crs_summary <- data.frame(variable = character(), crs = character(), 
                                n_files = integer(), stringsAsFactors = FALSE)
      #----
      
      
      
      
      # Loop through each climate variable directory
      for(input_dir in var_directories) {
            
            
            # Extract variable name from directory path
            var_name <- basename(input_dir)
            if(var_name %in% names(compiled_var_list)) {
                  warning(paste0("Variable '", var_name, "' already processed; skipping duplicate directory."))
                  next
            }
            message(paste0("\n=== Processing variable: ", var_name, " ==="))
            
            
            # Detect file type and select appropriate files    ----
            processed_dir <- file.path(input_dir, "processed")
            rescaled_dir <- file.path(input_dir, "rescaled")
            
            # Detect file type and select appropriate files
            processed_files <- list.files(processed_dir, pattern = "\\.nc$", full.names = FALSE)
            
            # Force use of rescaled files if they exist (for ANUCLIM)
            rescaled_files <- list.files(rescaled_dir, pattern = "\\.nc$", full.names = FALSE)
            if(length(rescaled_files) > 0) {
                  message("  Using rescaled files")
                  files_to_process <- rescaled_files
                  file_dir <- rescaled_dir
            } else {
                  message("  Using Original Resolution files")      
                  files_to_process <- processed_files
                  file_dir <- processed_dir
            }
            
            
            if(length(files_to_process) == 0) {
                  warning(paste0("No valid files found in ", input_dir))
                  next
            }
            
            message(paste0("  Found ", length(files_to_process), " files to process"))
            #----
            
            
            
            # Initialize list to store yearly data for this variable
            yearly_data_list <- list()
            var_crs_list <- c()
            
            
            # Loop through each file (year) for this variable and process the raster stack:    ----
            for(file_name in files_to_process) {
                  
                  # Extract year from raster file
                  year <- str_extract(file_name, "\\d{4}")
                  
                  if(is.na(year)) {
                        warning(paste0("Could not extract year from filename: ", file_name))
                        next
                  }
                  
                  message(paste0("  Extracting year ", year))
                  
                  tryCatch({
                        
                        # Read the raster stack
                        raster_data <- terra::rast(file.path(file_dir, file_name))
                        
                        # Store CRS
                        var_crs_list <- c(var_crs_list, as.character(crs(raster_data, proj = TRUE)))
                        
                        # Transform centroids to raster CRS
                        centroids_sf_proj <- st_transform(centroids_sf, crs = crs(raster_data, proj = TRUE))
                        
                        # Extract values (terra::extract returns a data.frame: first column = ID, rest = layers)
                        extracted_values <- terra::extract(raster_data, vect(centroids_sf_proj))
                        
                        # Remove the ID column
                        values_mat <- as.matrix(extracted_values[,-1])
                        
                        # Check if raster has multiple layers
                        n_layers <- ncol(values_mat)
                        n_centroids <- nrow(values_mat)
                        
                        # Expand centroids for each layer
                        cent_expanded <- cent_coords_dt[rep(1:.N, times = n_layers)]
                        
                        # Flatten values
                        values_vec <- as.vector(values_mat)
                        
                        # Determine dates for layers
                        if (!is.null(terra::time(raster_data))) {
                              raster_dates <- as.IDate(terra::time(raster_data))
                        } else {
                              year <- str_extract(file_name, "\\d{4}")
                              raster_dates <- seq(as.IDate(paste0(year, "-01-01")), by = 1, length.out = n_layers)
                        }
                        
                        dates_expanded <- rep(raster_dates, each = n_centroids)
                        
                        # Build the final data.table
                        extracted_dt <- copy(cent_expanded)
                        extracted_dt[, (var_name) := values_vec]
                        extracted_dt[, clim_date := dates_expanded]
                        
                        # Add to yearly list
                        yearly_data_list[[year]] <- extracted_dt
                        
                        # Clean up
                        rm(raster_data, extracted_values)
                        gc()
                        
                  }, error = function(e) {
                        warning(paste0("Error processing ", file_name, ": ", e$message))
                  })
            }
            #----
            
            
            
            
            # CRS checking for this variable    ----
            if(check_crs & length(var_crs_list) > 0) {
                  unique_crs <- unique(var_crs_list)
                  
                  if(length(unique_crs) > 1) {
                        warning(paste0("Variable '", var_name, "' has files with different CRS:"))
                        for(crs_val in unique_crs) {
                              warning(paste0("  ", crs_val))
                        }
                  }
                  
                  # Store CRS info for summary
                  crs_summary <- rbind(crs_summary, 
                                       data.frame(variable = var_name,
                                                  crs = unique_crs[1],
                                                  n_files = length(files_to_process),
                                                  stringsAsFactors = FALSE))
            }
            #----
            
            
            # Reshape data for this variable    ----
            if(length(yearly_data_list) == 0) {
                  warning(paste0("No data extracted for variable: ", var_name))
                  next
            }
            
            
            # Combine all yearly data.tables for this variable
            all_years_dt <- rbindlist(yearly_data_list, use.names = TRUE, fill = TRUE)
            
            # Already in long format: one column per variable + lat/lon/centroid.id/clim_date
            compiled_var_list[[var_name]] <- all_years_dt
            
            message(paste0("  Variable ", var_name, " complete: ", nrow(all_years_dt), " records"))
            
            # Clean up
            rm(yearly_data_list, all_years_dt)
            gc()
            
            
            #---- 
            
      }   #  end variable loop        
      
      
      
      
      
      # Checking that data was successfully extracted from the rasters    ----
      if(length(compiled_var_list) == 0) {
            stop("No climate data was successfully extracted from any variable")
      }
      
      message(paste0("Combining ", length(compiled_var_list), " variables: ", paste(names(compiled_var_list), collapse = ", ")))
      #----
      
      
      
      # Ensuring that all variables have the consistent keys for the "full_join" to avoid duplication    ----
      key_counts <- lapply(compiled_var_list, function(df) {
            df %>%
                  distinct(lat, lon, centroid.id, clim_date) %>%
                  nrow()
      })
      
      diag_df <- data.frame(
            variable = names(compiled_var_list),
            n_keys = unlist(key_counts)
      )
      
      print(diag_df)
      
      if(length(unique(diag_df$n_keys)) != 1) {
            stop("⚠️ Not all variables have the same number of unique join keys. This may cause row duplication.")
      }
      #----
      
      
      
      
      # Merge all variables using data.table ----
      
      # Ensure all elements are data.tables
      compiled_var_list <- lapply(compiled_var_list, as.data.table)
      
      # New key columns for single-layer raster
      key_cols <- c("lat", "lon", "centroid.id", "clim_date")
      
      # Set keys for fast joining
      lapply(compiled_var_list, setkeyv, key_cols)
      
      # Merge all variables iteratively
      all_clim_dt <- Reduce(function(x, y) merge(x, y, by = key_cols, all = TRUE),
                            compiled_var_list)
      
      
      
      message(paste0("Total records after merging: ", nrow(all_clim_dt)))
      #----
      
      
      
      
      # Format date columns    ----
      
      # Convert date column to proper Date object
      all_clim_dt[, clim_date := as.IDate(clim_date)]
      all_clim_dt[, clim_year := year(clim_date)]       
      all_clim_dt[, clim_month := month(clim_date)]
      all_clim_dt[, clim_m.day := mday(clim_date)]
      all_clim_dt[, clim_day.month := paste0(clim_m.day, ".", clim_month)]
      all_clim_dt[, id := paste0(centroid.id, "_", year(clim_date))]
      
      # Reorder columns
      setcolorder(all_clim_dt, c("lat", "lon", "centroid.id", "id", "clim_date", "clim_year",
                                 "clim_month", "clim_m.day", "clim_day.month",
                                 setdiff(names(all_clim_dt), c("lat","lon","centroid.id","id",
                                                               "clim_date","clim_year",
                                                               "clim_month","clim_m.day","clim_day.month"))))
      #----
      
      
      
      
      
      # Save final compiled dataframe and output to user    ----
      saveRDS(all_clim_dt, file = output_filepath)
      message(paste0("Compiled climate data saved to: ", output_filepath))
      
      return(all_clim_dt)
      #-----
}


########################################################




##                   Example Syntax:                  ##
########################################################


# clim_dir <- c("github/clim_data/daily_rain", "github/clim_data/radiation", 
#               "github/clim_data/tmin", "github/clim_data/tmax",
#               "github/clim_data/t_min", "github/clim_data/t_max")
# 
# 
# centroids <- read.csv("github/centroid_lat_lons.csv")
# 
# 
# test_conversion <- extract_and_compile_clim.data(var_directories = clim_dir, 
#                                                  centroid_df = centroids, 
#                                                  output_filepath = "github/compiled_raster_clim_df.RDS",
#                                                  check_crs = T)


########################################################






