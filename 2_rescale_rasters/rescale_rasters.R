
#           rescale_rasters


##                Function Description:               ##
########################################################


# Rescales downloaded and processed raster grids to the same resolution as a user supplied template raster. 
      # This facilitates using climate variables from ANUClimate (0.01x0.01) with SILO or AGCD (0.05x0.05)



# Rasters are rescales to the resolution of the template raster
      # Template raster MUST have a coarser resolution than those being rescaled. 

# Since AWAP and SILO have identical scales, even if using all three sources of data, only one template file is required. 



# computes averages or sums for each cell depending on the variable being rescaled. 

# If the variable being rescaled is precipitation, evaporation or evapotranspiration:
      # the values will be summed to retain a "total" value for the cell.

#All other variables are averaged.



# Rescaled raster files are saved into a sub-directory within the variable directory called "rescaled"
# i.e. user_directory/rain/rescaled


########################################################




##                     User Inputs                    ##
########################################################


#    -    var_directories           -  a vector of variable directories containing the ANUClimate files which need to be rescaled. 


#...............................................................................................................................................................................


#    -    template_file             -  the path to a template file - i.e. a "processed" SILO or AWAP file from previous functions.


########################################################




##                      Function                      ##
########################################################


rescale_rasters <- function(var_directories,
                                   template_file) {
      
      # Ensuring Packages are Loaded:
      library(terra)
      library(tidyverse)
      
      
      # Input Validation    ----
      
      # Check that template file exists
      if(!file.exists(template_file)) {
            stop("Template file does not exist. Provide a valid SILO or AWAP NetCDF file path.")
            cat("\n")
      }
      
      # Check that ANUCLIM directories exist
      for(dir in var_directories) {
            if(!dir.exists(dir)) {
                  stop(paste0("target directory does not exist: ", dir))
                  cat("\n")
            }
      }
      
      
      
      
      
      # Load Template Raster to Define Target Grid    ----
      template_raster <- terra::rast(template_file)
      
      message("Target grid specifications:")
      message(paste0("  Resolution: ", res(template_raster)[1], " x ", res(template_raster)[2]))
      message(paste0("  Extent: ", paste(as.vector(terra::ext(template_raster)), collapse = ", ")))
      message(paste0("  CRS: ", crs(template_raster)))
      #----
      
      
      
      # Process Each ANUCLIM Variable Directory    ----
      for(var_dir in var_directories) {
            
            input_dir <- file.path(var_dir, "processed")  # append 'processed' to parent dir
            if(!dir.exists(input_dir)) {
                  warning(paste0("Processed folder does not exist: ", input_dir))
                  cat("\n")
                  next
            }
            
            # Extract variable name from directory path
            var_name <- basename(var_dir)
            message(paste0("\nProcessing variable: ", var_name))
            
            
            # Get list of all annual NetCDF files in this directory
            annual_files <- list.files(input_dir, pattern = "\\.nc$", full.names = TRUE)
            
            # Exclude reprojected files
            annual_files <- annual_files[!grepl("rescaled", basename(annual_files))]
            
            if(length(annual_files) == 0) {
                  warning(paste0("No files found in: ", input_dir))
                  cat("\n")
                  next
            }
            
            message(paste0("  Found ", length(annual_files), " annual files to rescale"))
            cat("\n")
            
            
            
            # Process each annual file    ----
            for(file_path in annual_files) {
                  
                  r <- terra::rast(file_path)
                  
                  # Ensure storing of metadata:
                  original_time <- terra::time(r)
                  original_names <- names(r)
                  
                  # Logging progress for the user
                  message(paste0("  Processing: ", basename(file_path)))
                  message(paste0("    Input resolution: ", res(r)[1], " x ", res(r)[2]))
                  message(paste0("    Input layers: ", nlyr(r)))
                  cat("\n")
                  
                  # Check if the rasters need to be reprojected - they should not as they were all projected to crs:4326
                  if(!terra::same.crs(r, template_raster)) {
                        message("    Reprojecting CRS before aggregation...")
                        cat("\n")
                        r <- terra::project(r, crs(template_raster), method = "bilinear")
                  }
                  
                  # Determining the method of resampling grid cells:
                  # if rainfall or evaporation values, these are summed
                  # # Any other variables are averaged:
                  
                  #  Defining the variables to be summed 
                  evap_rain_var.names <- c("precip", "daily_rain", "rain",
                                           "evap_pan", "evap_syn", "evap_comb", "evap_morton_lake", "evap",
                                           "et_short_crop", "et_tall_crop", "et_morton_lake", "et_morton_potential", "et_morton_wet")
                  
                  # Conditionally resampling raster:
                  if(var_name %in% evap_rain_var.names) {
                        # resample raster cells to compute coarser resolution
                        r_aligned <- terra::resample(r, template_raster, method = "sum")  
                        message("    Using SUM to resample Precipitation, Evaporation and Evapotranspiration Values")
                  } else {
                        # resample raster cells to compute coarser resolution
                        r_aligned <- terra::resample(r, template_raster, method = "average")  
                        message("    Using AVERAGE For All Variables Other than Precipitation, Evaporation and Evapotranspiration")
                  }
                  
                  # Restore time metadata
                  if(!is.null(original_time) && length(original_time) == nlyr(r_aligned)) {
                        terra::time(r_aligned) <- original_time
                  }
                  
                  # Restore layer names
                  if(length(original_names) == nlyr(r_aligned)) {
                        names(r_aligned) <- original_names
                  }
                  message(paste0("    Output resolution: ", res(r_aligned)[1], " x ", res(r_aligned)[2]))
                  message(paste0("    Output layers: ", nlyr(r_aligned)))
                  
                  
                  
                  # Save reprojected/rescaled raster
                  out.dir <- file.path(var_dir, "rescaled")
                  dir.create(out.dir, recursive = TRUE, showWarnings = FALSE)
                  out_file <- file.path(out.dir, sub("_processed\\.nc$", "_rescaled.nc", basename(file_path)))
                  message(paste0("Input: ", basename(file_path), " -> Output: ", basename(out_file)))
                  cat("\n")
                  
                  # saving the new raster
                  terra::writeCDF(r_aligned, out_file, varname = var_name, overwrite = TRUE, compression = 4)
                  
                  # check if metadata was preserved:
                  r_check <- terra::rast(out_file)
                  if(!is.null(original_time) && is.null(terra::time(r_check))) {
                        warning("    Time metadata may not have been preserved in NetCDF")
                        cat("\n")
                  }
                  rm(r_check)
                  
                  #cleaning the environment
                  rm(r, r_aligned)
                  gc()
            } 
            
            message(paste0("Reprojected files saved to: ", out.dir))
            cat("\n")
      }
      
      message("Note: Files were aggregated using cell sums (Precipitation, Evaporation, Evapotranspiration)  OR  cell averages (all other variables).")
      message("      Use these rescaled files when combining with SILO/AWAP data")
}


########################################################




##                   Example Syntax:                  ##
########################################################


# rescale_rasters(var_directories = c("github/clim_data/t_min", "github/clim_data/t_max", 'github/clim_data/rain'),
#                       template_file = "github/clim_data/daily_rain/processed/radiation_2020_processed.nc")


########################################################