#           assign_clim.data


##                Function Description:               ##
########################################################


# Assigns climate data to individual samples based on their location and dates.
      # supplied through a metadata file containing rounded latitude and longitude coordinates, sample ID and date of sampling. 

# User must ensure that the metadata file has data for the following and that the collumns are named as such:
            # sample.id - a unique sample identifier
            # lat - in decimal degrees
            # lon - in decimal degrees
            # date - a date of sample collection (formatted as dd/mm/yyyy)



# Facilitates user defined periods for which to collect climate data for each individual
      # Allows collection of data before and after the sample's assigned date. 



# User MUST ensure that they have collected the required years of climate data based on:
      # the inidividuals in their dataset
      # the time period to collect climate data for each individual



# Saves the resulting dataframe to an .RDS file


########################################################




##                     User Inputs                    ##
########################################################


#    -    grid_df                   -  The gridded Climate Dataframe produced by the "compile_raster_dfs" function.


#...............................................................................................................................................................................


#    -    sample_df                 -  a dataframe of samples for which the climate data is to be collected. 
#                                         -  Each row should be a unique sample and sample ID  
#                                         -  Must contain the following collumns, named as described:
#                                                -  sample.id    - Sample ID for each sample
#                                                -  lat          - latitude for each sample (rounded to match the target resolution)
#                                                -  lon          - longitude for each sample (rounded to match the target resolution)
#                                                -  date         - date of collection of sample (a character string as "dd/mm/yyyy" - i.e. the 24th of December, 1965 as "24/12/1965")
#                                                -  Example sample_df:
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


#...............................................................................................................................................................................


#    -    pre_period                -  the length of time prior to the sample collection date for which to collate climate data
#                                         -  formatted as a List of Integers where:
#                                               - First Element  = Number of years
#                                               - Second Element = number of Months
#                                               - Third Element = Number of Days
                                                #  Capturing from  1 Year prior to capture date                          list(1, 0, 0)
                                                #  Capturing from 6 months prior to capture date                         list(0, 6, 0)
                                                #  Capturing from 10 Days prior to capture date                          list(0, 0, 10)
                                                #  Capturing from 2 years, 9 months and 4 days prior to capture date     list(2, 9, 4)


#...............................................................................................................................................................................


#    -    include_start_date        -  IF TRUE, then the collection includes the first fence date


#...............................................................................................................................................................................


#    -    post_period               -  the length of time following the sample collection date for which to collate climate data
#                                         -  formatted as a List of Integers where:
#                                               - First Element  = Number of years
#                                               - Second Element = number of Months
#                                               - Third Element = Number of Days
                                                #  Capturing until  1 Year after to capture date                          list(1, 0, 0)
                                                #  Capturing until 6 months after to capture date                         list(0, 6, 0)
                                                #  Capturing until 10 Days after to capture date                          list(0, 0, 10)
                                                #  Capturing until 2 years, 9 months and 4 days after to capture date     list(2, 9, 4)


#...............................................................................................................................................................................


#    -    include_end_date          -  IF TRUE, then the collection includes the final fence date


#...............................................................................................................................................................................


#    -    output_directory          -  The path (including file name and extension) to the location where the output will be saved (as .RDS)


########################################################




##                      Function                      ##
########################################################


assign_clim.data <- function(grid_df,
                              sample_df,
                             pre_period,
                             include_start_date,
                             post_period,
                             include_end_date,
                             output_directory) {
      
      # Ensuring the required packages are loaded:
      library(tidyverse)
      library(data.table)
      
      
      # Ensuring that the gridded climate dataframe has all date objects formatted correctly    ----
      grid_df$clim_date <- as.Date(grid_df$clim_date)
      #----
      
      
      if (dir.exists(output_directory)) {
            stop("Output directory path is a folder, please provide a full file path including filename.rds")
      }
      
      
      # Defining the inclusion and exclusion of fence dates    ----
      if(include_start_date == TRUE) {
            pre.fence_buffer <- 0
      } else if(include_start_date == FALSE) {
            pre.fence_buffer <- 1
      } else {
            stop(paste0("Define Inclusion/Exclusion of Start Date"))
      }
      
      if(include_end_date == TRUE) {
            post.fence_buffer <- 0
      } else if(include_end_date == FALSE) {
            post.fence_buffer <- 1
      } else {
            stop(paste0("Define Inclusion/Exclusion of end Date"))
      }
      #----
      
      
      # Extracting the pre-collection date periods    ----
      pre.period <- years(pre_period[[1]]) + months(pre_period[[2]]) + days(pre_period[[3]]) - days(pre.fence_buffer)
      
      # Extracting the post-collection date periods    ----
      post.period <- years(post_period[[1]]) + months(post_period[[2]]) + days(post_period[[3]]) - days(post.fence_buffer)
      #----
      
      
      # processing date periods for the samples in order to filter the climate data from there
      # Converting the date object to a lubridate format
      # Calculating the start and end dates for each sample   ----
      meta <- sample_df %>%
            dplyr::select(sample.id, lat, lon, date) %>%
            mutate(date = dmy(date),
                   start_date = date - pre.period,
                   end_date = date + post.period) 
      #----
      
      
      
      # removing Unneccessary dates to reduce computational load    ----
      grid_df <- grid_df[grid_df$clim_date >= min(meta$start_date) & grid_df$clim_date <= max(meta$end_date),]
      #----
      
      
      
      # Converting the dataframe to a data.table:
      grid_dt <- as.data.table(grid_df)
      setkey(grid_dt, lat, lon, clim_date)
      
      
      # Applying a function for each row in the data:
      results_list <- lapply(1:nrow(meta), function(i) {
            
            # Extracting the indexing values for each individual:
            meta_sample.id <- meta$sample.id[i]
            sample.lat <- meta$lat[i]
            sample.lon <- meta$lon[i]
            sample.start_date <- meta$start_date[i]
            sample.end_date <- meta$end_date[i]
            
            
            # Filtering the data.table using the indexing keys set previously:
            ind.clim.dt <- grid_dt[lat == sample.lat
                                   & lon == sample.lon
                                   & clim_date >= sample.start_date
                                   & clim_date <= sample.end_date]
            
            # adding a sample.id value:
            ind.clim.dt[, sample.id := meta_sample.id]
            
            
            # # Printing Progress
            if (i %% 50 == 0 || i == nrow(meta)) {
                  message("Processed ", i, "/", nrow(meta))
            }
            
            # Returning the result
            return(ind.clim.dt)
      })
      
      # Combining the resulting data.tables:
      all.inds_clim.df <- rbindlist(results_list)
      
      # Cleaning the environment
      rm(grid_df, grid_dt, results_list)
      gc()     
      
      
      # Converting back to a data.frame for compatibility:
      all.inds_clim.df <- all.inds_clim.df %>%
            as.data.frame() %>%
            dplyr::select(sample.id, lat, lon, centroid.id, clim_date, everything())
      #----
      
      
      
      # merging with the metadata again so that we can have the sampling collection date    ----
      ind_collection <- meta %>%
            dplyr::select(sample.id, lat, lon, date)
      
      ind.clim_meta <- merge(ind_collection, all.inds_clim.df, by = c("sample.id", "lat", "lon"))
      
      rm(all.inds_clim.df)
      #----
      
      
      # Saving the output:
      saveRDS(ind.clim_meta, output_directory)
      
      
      
      # Reporting the Output ----
      n.check <- length(unique(ind.clim_meta$sample.id))
      
      message(paste0("Climate Data Assigned to ", n.check, " Individuals.", "\n",
                     
                     "Check the Number of Records Associated with Each Individual:", "\n",
                     
                     "All inds should have the same number of records associated (with the potential exception of leap years)."))
      
      
      records_per_sample <- as.data.frame(table(ind.clim_meta$sample.id))
      colnames(records_per_sample) <- c("sample.id", "n_records")
      print(table(records_per_sample$n_records))
      
      print(paste0("All inds should have the same number of records as there are days in the user defined interval."))
      #----     
      
      
      
      return(ind.clim_meta)
}


########################################################




##                   Example Syntax:                  ##
########################################################


# test_compile.raster <- readRDS("github/compiled_raster_clim_df.RDS")
# 
# ind_meta <- read.csv("github/Example_metadata.csv")
# 
# 
# 
# test_assign_clim.data <- assign_clim.data(grid_df = test_compile.raster,
#                                           sample_df = ind_meta,
#                                           pre_period = c(1,0,0),
#                                           include_start_date = FALSE,
#                                           post_period = c(0,0,0), 
#                                           include_end_date = TRUE,
#                                           output_directory = "github/test_assign_ind.clim.RDS")


########################################################