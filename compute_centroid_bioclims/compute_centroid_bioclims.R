#           compute_centroid_bioclims


##                Function Description:               ##
########################################################


# This function computes bioclimatic indices for each sample.
# based on the indiviaul sample climate period supplied from the previous function.

# NOTE: This function is designed to compute BIOclimatic indices for each sample on the assumption
# that each sample has 1 year of climate data (365 or 366 days)
# The output of this function will not be accurate to computed bioclimatic indices if this time period is not provided. 



# Computes BIOCLIM 1-27 using daily values for:
# maximum temperature, minimum temperature, precipitation and radiation
# allowing the user to decide which BIOCLIM indices they would like to compute. 
# Allows the user to use the above 4 variables from any combination of the 3 datasets (SILO, AGCD, ANUClimate)



# In order to compute all indices, the function requires all 4 of the above described climate variables,
# however, the function will only fail if the user does not provide the specific climate variables required
#  for the indices they have selected



# Optionally allows the user to compute average bioclimatic indices across years for each grid cell. 



# Saves output dataframe to RDS


########################################################




##                     User Inputs                    ##
########################################################


#    -    centroid_clim.data        -  The dataframe produced by the extract_and_compile_clim.data


#...............................................................................................................................................................................


#    -    bioclim_indices           -     A vector of numbers identifying which bioclimatic indices the user wants the function to compute:
#                                         Example:    c(1, 2, 3, 4, 5, 6, 7, 8, 15, 22, 21, 26)
#                                         -  Indices Range from 1 through to 27:
#                                                     1 - 11 = Temperature Based Indices
#                                                     12 - 19 = Precipitation Indices
#                                                     20 - 27 = Radiation Indices
#                                         -  NOTE: Different Indices Require Different Variables to be included:
                                                      #    BIO1  -     Max Temp  |  Min Temp
                                                      #    BIO2  -     Max Temp  |  Min Temp
                                                      #    BIO3  -     Max Temp  |  Min Temp
                                                      #    BIO4  -     Max Temp  |  Min Temp 
                                                      #    BIO5  -     Max Temp
                                                      #    BIO6  -     Min Temp
                                                      #    BIO7  -     Max Temp  |  Min Temp
                                                      #    BIO8  -     Max Temp  |  Min Temp | Precipitation
                                                      #    BIO9  -     Max Temp  |  Min Temp | Precipitation
                                                      #    BIO10  -    Max Temp
                                                      #    BIO11  -    Min Temp
                                                      #    BIO12  -    Precipitation
                                                      #    BIO13  -    Precipitation
                                                      #    BIO14  -    Precipitation
                                                      #    BIO15  -    Precipitation
                                                      #    BIO16  -    Precipitation
                                                      #    BIO17  -    Precipitation
                                                      #    BIO18  -    Precipitation  |  Max Temp
                                                      #    BIO19  -    Precipitation  |  Min Temp
                                                      #    BIO20  -    Radiation
                                                      #    BIO21  -    Radiation
                                                      #    BIO22  -    Radiation
                                                      #    BIO23  -    Radiation
                                                      #    BIO24  -    Radiation  |  Precipitation
                                                      #    BIO25  -    Radiation  |  Precipitation
                                                      #    BIO26  -    Radiation  |  Max Temp
                                                      #    BIO27  -    Radiation  |  Min Temp


#...............................................................................................................................................................................


#    -    var.names                 -     A vector of the variables to be used to compute bioclimatic indices for each Individual:
#                                         -  Must Include one or more of the following:
#                                                     - Maximum Temperature         -     tmax (AWAP) or max_temp (SILO) or t_max (ANUCLIM)
#                                                     - Minimum Temperature         -     tmin (AWAP) or min_temp (SILO) or t_min (ANUCLIM)
#                                                     - Precipitation               -     precip (AWAP) or daily_rain (SILO) or rain (ANUCLIM)
#                                                     - Radiation                   -     radiation (SILO) or srad (ANUCLIM)
#                                         - The function will handle having multiple synonomous variables (see above) in the dataframe, using only those called in "var.names"
#                                               NOTE: If there are several version of the same climate variable, the function will force an error.
#                                                    BOM AWAP Variable    |    SILO Variable    |    ANUCLIM          
#                                       ..................................|.........................................
#                                                    precip               |    daily_rain       |    rain
#                                                    tmax                 |    max_temp         |    t_max
#                                                    tmin                 |    min_temp         |    t_min
#                                                                         |    radiation        |    srad


#...............................................................................................................................................................................


#    -    av_period_start           -    A numerical value describing the year which starts the averaging period sequence


#...............................................................................................................................................................................


#    -    av_period_end             -    A numerical value describing the final year in the averaging period sequence


#...............................................................................................................................................................................


#    -    av_period_by              -    A numerical value describing how many years of indices should be averaged to produce the final detaset. 
#                                               -  Indices are calculated for each year prior to averaging across user defined periods. 
#                                               -  If you wanted decadal averages for the indices, then averaging-period = 10
#                                               -  If you don't want the values averaged, then averaging_period = 1


#...............................................................................................................................................................................


#    -    output_directory          -    a path (including file name and extension) to the location where the output will be saved (as .RDS)



########################################################




##                      Function                      ##
########################################################


compute_centroid_bioclims <- function(centroid_clim.data,
                                      bioclim_indices,
                                      var.names,
                                      av_period_start,
                                      av_period_end,
                                      av_period_by,
                                      output_directory) {
      
      
      # Loading required Packages:
      library(tidyverse)
      
      
      # Creating a copy of the data to manipulate
      clim <- centroid_clim.data
      
      #Initialising a list to output results.
      results_list <- list()
      
      
      # checking User input is valid   ----
      
      # Bioclim indices
      if(all(bioclim_indices %in% c(1:27)) == FALSE) {
            stop("Invalid Bioclimatic Indice Values. Values of Bioclimatic Indices should Range from 1 - 27.")
      }
      
      
      
      # Climate variables:
      valid_var.names <- c("tmax", "tmin", "precip", "max_temp", "min_temp", "daily_rain", "radiation")
      
      if(all(var.names %in% valid_var.names) == FALSE) {
            stop("Invalid Climate Variable Names Supplied. Check supplied variable names.")
      }
      #----
      
      
      
      # Clearing Potential Duplicate Climate values (BOM AWAP vs SILO vs ANUClim) ----
      
      # Define standardization rules: canonical name -> alternative names
      standardization_map <- list(
            precip = c("rain", "daily_rain"),
            tmax = c("max_temp", "t_max"),
            tmin = c("min_temp", "t_min"),
            rad = c("srad", "radiation")
      )
      
      # Identify variables actually present in the dataset
      present_vars <- names(clim)
      
      # Process each canonical variable
      for (canonical in names(standardization_map)) {
            
            alternatives <- standardization_map[[canonical]]
            
            # Find which version exists in var.names (if any)
            existing_in_varnames <- c(canonical, alternatives)[c(canonical, alternatives) %in% var.names]
            
            if (length(existing_in_varnames) > 0) {
                  
                  primary_var <- existing_in_varnames[1]  # The one specified in var.names
                  
                  # Remove all other alternatives that exist in the dataset
                  vars_to_remove <- setdiff(c(canonical, alternatives), primary_var)
                  vars_to_remove <- intersect(vars_to_remove, present_vars)
                  
                  if (length(vars_to_remove) > 0) {
                        clim <- clim %>% 
                              dplyr::select(-all_of(vars_to_remove))
                        
                        message(paste0("Removed duplicate variable(s) '", 
                                       paste(vars_to_remove, collapse = "', '"), 
                                       "' because '", primary_var, "' is specified in var.names"))
                  }
                  
                  # Rename to canonical form if needed
                  if (primary_var != canonical && primary_var %in% names(clim)) {
                        clim <- clim %>%
                              dplyr::rename(!!canonical := !!primary_var)
                        
                        var.names[var.names == primary_var] <- canonical
                        
                        message(paste0("Standardized '", primary_var, "' to '", canonical, "'"))
                  }
            }
      }
      #----
      
      
      # Standardising overlap names - Precipitation    ----
      if ("daily_rain" %in% var.names) {
            
            clim <- clim %>%
                  dplyr::rename(precip = daily_rain)
            
            var.names[var.names == "daily_rain"] <- "precip"
      }
      
      # Standardising overlap names - Max Temp    ----
      if ("max_temp" %in% var.names) {
            
            clim <- clim %>%
                  dplyr::rename(tmax = max_temp)
            
            var.names[var.names == "max_temp"] <- "tmax"
      }
      
      # Standardising overlap names - Min Temp    ----
      if ("min_temp" %in% var.names) {
            
            clim <- clim %>%
                  dplyr::rename(tmin = min_temp)
            
            var.names[var.names == "min_temp"] <- "tmin"
            
      }
      
      # Shortening Variable names - Radiation    ----
      if ("radiation" %in% var.names) {
            
            clim <- clim %>%
                  dplyr::rename(rad = radiation)
            
            var.names[var.names == "radiation"] <- "rad"
            
      }
      #----
      
      
      
      # Checking That the variables required to calculate requested indices are present    ----
      
      # Defining which indices require which variables:
      indices_depend_max.temp <- c(1, 2, 3, 4, 5, 7, 8, 9, 10, 18, 26)
      indices_depend_min.temp <- c(1, 2, 3, 4, 6, 7, 8, 9, 11, 19, 27)
      indices_depend_precip <- c(8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 24, 25)
      indices_depend_rad <- c(20, 21, 22, 23, 24, 25, 26, 27)
      
      
      
      # Check that each indice to be computed has the required variables present:
      for(i in bioclim_indices) {
            
            if(i %in% indices_depend_max.temp & !("tmax" %in% var.names)) {
                  stop("Maximum Temperature Variables Required to Compute BIO", i, " Required - Revise Input Variables.")
            }
            
            if(i %in% indices_depend_min.temp & !("tmin" %in% var.names)) {
                  stop("Minimum Temperature Variables Required to Compute BIO", i, " Required - Revise Input Variables.")
            }
            
            if(i %in% indices_depend_precip & !("precip" %in% var.names)) {
                  stop("Precipitation Variables Required to Compute BIO", i, " Required - Revise Input Variables.")
            }
            
            if(i %in% indices_depend_rad & !("rad" %in% var.names)) {
                  stop("Radiation Variables Required to Compute BIO", i, " Required - Revise Input Variables.")
            }
      }
      #----
      
      
      
      
      # Formatting all Required Date and Time data for the climate data    ----
      clim$clim_date <- date(clim$clim_date)
      clim$clim_year <- year(clim$clim_date)
      clim$clim_month <- month(clim$clim_date)
      clim$clim_m.day <- day(clim$clim_date)
      #----
      
      
      
      
      ############################################    Monthly Aggregations    ##############################################
      
      # Temperature Monthly Aggregations      ----
      if("tmax" %in% var.names & "tmin" %in% var.names) {
            
            # Computing Daily Mean Temperature
            clim$daily_av_temp <- (clim$tmin + clim$tmax)/2
            clim$diurnal_range <- clim$tmax - clim$tmin
            clim$daily_av_temp_k <- clim$daily_av_temp + 273.15
            
            
            # Monthly Aggregations
            monthly_av_temp <- aggregate(daily_av_temp ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_av_temp = daily_av_temp)
            
            monthly_max_temp <- aggregate(tmax ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_max_temp = tmax)
            
            monthly_min_temp <- aggregate(tmin ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_min_temp = tmin)
            
            monthly_av_temp_k <- aggregate(daily_av_temp_k ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_av_temp_k = daily_av_temp_k)
            
            # Merging back into Clim:
            clim <- clim %>%
                  left_join(monthly_av_temp, by = c("centroid.id", "clim_month", "clim_year")) %>%
                  left_join(monthly_max_temp, by = c("centroid.id", "clim_month", "clim_year")) %>%
                  left_join(monthly_min_temp, by = c("centroid.id", "clim_month", "clim_year")) %>%
                  left_join(monthly_av_temp_k, by = c("centroid.id", "clim_month", "clim_year"))
            
            
      } else if ("tmax" %in% var.names) {
            
            # Computing Monthly Aggregation
            monthly_max_temp <- aggregate(tmax ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_max_temp = tmax)
            
            # Merging back into Clim:
            clim <- clim %>%
                  left_join(monthly_max_temp, by = c("centroid.id", "clim_month", "clim_year"))
            
      } else if ("tmin" %in% var.names) {
            
            # Computing Monthly Aggregation
            monthly_min_temp <- aggregate(tmin ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_min_temp = tmin)
            
            # Merging back into Clim:
            clim <- clim %>%
                  left_join(monthly_min_temp, by = c("centroid.id", "clim_month", "clim_year"))            
            
      }
      #----
      
      
      # Precipitation Monthly Aggregations      ----
      if("precip" %in% var.names) {
            
            # Monthly Aggregations:
            monthly_av_rain <- aggregate(precip ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_av_rain = precip)
            
            monthly_tot_rain <- aggregate(precip ~ centroid.id + clim_month + clim_year, data = clim, FUN = sum)%>%
                  dplyr::rename(month_tot_rain = precip)
            
            # merging back into clim:
            clim <- clim %>% 
                  left_join(monthly_av_rain, by = c("centroid.id", "clim_month", "clim_year")) %>%
                  left_join(monthly_tot_rain, by = c("centroid.id", "clim_month", "clim_year"))
      }
      #----
      
      
      # Radiation Monthly Aggregations      ----
      if("rad" %in% var.names) {
            
            # Monthly Aggregations:
            monthly_av_rad <- aggregate(rad ~ centroid.id + clim_month + clim_year, data = clim, FUN = mean)%>%
                  dplyr::rename(month_av_rad = rad)
            
            
            # merging back into clim:
            clim <- clim %>% 
                  left_join(monthly_av_rad, by = c("centroid.id", "clim_month", "clim_year"))
      }
      #----
      
      
      
      ############################################    Quarterly Aggregations    ##############################################
      
      # Quarter Definitions     ----
      quart_combos <- list(c(1, 2, 3),  c(2, 3, 4), 
                           c(3, 4, 5),  c(4, 5, 6), 
                           c(5, 6, 7),  c(6, 7, 8), 
                           c(7, 8, 9),  c(8, 9, 10), 
                           c(9, 10, 11),  c(10, 11, 12),
                           c(11, 12, 1),   c(12, 1, 2))
      #----
      
      
      # Running through each quarter combination and computing values for that quarter    ----
      
      # Initialising an Empty List:
      q_results_list <- list()
      
      for (months in quart_combos) {
            
            
            # Restricting the dataframe to only those months found in this quarter:
            q_filtered.df <- clim %>%
                  dplyr::filter(clim_month %in% months)
            
            
            # Initialising an Empty List
            q_list <- list()
            
            
            # Temperature-based aggregations
            if("tmax" %in% var.names) {
                  q_list[[ "q_max_temp" ]] <- aggregate(tmax ~ centroid.id + clim_year, data = q_filtered.df, FUN = mean) %>%
                        dplyr::rename(q_max_temp = tmax)
            }
            
            if("tmin" %in% var.names) {
                  q_list[[ "q_min_temp" ]] <- aggregate(tmin ~ centroid.id + clim_year, data = q_filtered.df, FUN = mean) %>%
                        dplyr::rename(q_min_temp = tmin)
            }
            
            if(all(c("tmax","tmin") %in% var.names)) {
                  q_list[[ "q_av_temp" ]] <- aggregate(daily_av_temp ~ centroid.id + clim_year, data = q_filtered.df, FUN = mean) %>%
                        dplyr::rename(q_av_temp = daily_av_temp)
            }
            
            
            
            # Precipitation-based aggregations ----
            if("precip" %in% var.names) {
                  q_list[[ "q_tot_rain" ]] <- aggregate(precip ~ centroid.id + clim_year, data = q_filtered.df, FUN = sum) %>%
                        dplyr::rename(q_tot_rain = precip)
            }
            
            
            
            # Radiation-based aggregations ----
            if("rad" %in% var.names) {
                  q_list[[ "q_av_rad" ]] <- aggregate(rad ~ centroid.id + clim_year, data = q_filtered.df, FUN = mean) %>%
                        dplyr::rename(q_av_rad = rad)
            }
            
            
            # Combine into a single DF for this quarter
            if(length(q_list) > 0) {
                  q_df <- q_list %>% purrr::reduce(full_join, by = c("centroid.id", "clim_year"))
                  q_results_list[[ paste(months, collapse = "-") ]] <- q_df
            }
      }  
      
      
      # Bind All the Quarter Results:
      quarter_stats <- dplyr::bind_rows(q_results_list, .id = "quarter")
      quarter_stats$quarter <- as.factor(quarter_stats$quarter)
      
      # Rename columns
      names(quarter_stats) <- make.names(names(quarter_stats), unique = TRUE)
      #----
      
      
      ############################################    TEMPERATURE  -  Indice Calculations    ##############################################
      
      # Annual Mean Temperature - BIO1      ----
      #   -  Equal to the annual mean of the daily average temperature, calculated as the average between maximum and minimum temperature. 
      if (1 %in% bioclim_indices) {
            results_list[["1"]] <- aggregate(daily_av_temp ~ centroid.id + clim_year, data = clim, FUN = mean) %>%
                  dplyr::rename(bio1 = daily_av_temp)
      }
      #----
      
      
      
      # Mean Annual Diurnal Range  -  BIO2      ----
      #   -  Equal to the annual average of the difference between daily maximum and minimum temperatures. 
      if (any(c(2, 3) %in% bioclim_indices)) {      # BIO3 Depends on BIO2 to be computed - therefore, we include this in the conditional
            
            results_list[["2"]] <- aggregate(diurnal_range ~ centroid.id + clim_year, data = clim, FUN = mean) %>%
                  dplyr::rename(bio2 = diurnal_range)
      }
      #----
      
      
      
      ####    BIO3 computer AFTER BIO7 to avoid unnecssary Code
      
      
      
      
      # Temperature Seasonality (Standard Deviation)  -  BIO4      ----
      #   -  Equal to the SD of the monthly average of daily average temperatures (calculated as the mean of the maximum and minimum temperatures).
      if (4 %in% bioclim_indices) {
            
            # computing the standard deviation in monthly average temp in Kelvin
            month_av_temp_K_sd <- aggregate(month_av_temp_k ~ centroid.id + clim_year, data = clim, FUN = sd) %>%
                  dplyr::rename(month_av_K_sd = month_av_temp_k)
            
            # computing the yearly average of monthly average temp in Kelvin
            yearly_av_tempk <- aggregate(month_av_temp_k ~ centroid.id + clim_year, data = clim, FUN = mean) %>%
                  dplyr::rename(year_av_temp_k = month_av_temp_k)
            
            # merging dataframes together
            av_tempk_cv <- merge(month_av_temp_K_sd, yearly_av_tempk, by = c("centroid.id", "clim_year"))
            
            # computing BIO4 - 
            av_tempk_cv$bio4 <- (av_tempk_cv$month_av_K_sd/av_tempk_cv$year_av_temp_k)*100
            
            # saving Result
            results_list[["4"]] <- av_tempk_cv %>%
                  dplyr::select(centroid.id, clim_year, bio4)
            
            # removing all objects:
            rm(month_av_temp_K_sd, yearly_av_tempk, av_tempk_cv)
      }
      #----
      
      
      
      
      # Mean Maximum Temperature of Warmest Month - BIO5      ----
      #   -  Equal to the monthly average maximum daily temperature for the month with the highest monthly average daily maximum temperature. 
      if (any(c(5, 7, 3) %in% bioclim_indices)) {      # BIO7 and BIO3 Depend on BIO5 to be computed - therefore, we include this in the conditional
            
            results_list[["5"]] <- aggregate(month_max_temp ~ centroid.id + clim_year, data = clim, FUN = max) %>%
                  dplyr::rename(bio5 = month_max_temp)
      }
      #----
      
      
      
      
      # Mean Minimum Temperature of Coldest Month - BIO6      ----
      #   -  Equal to the monthly average minimum daily temperature for the month with the lowest monthly average daily minimum temperature. 
      if (any(c(6, 7, 3) %in% bioclim_indices)) {      # BIO7 and BIO3 Depend on BIO6 to be computed - therefore, we include this in the conditional
            
            results_list[["6"]] <- aggregate(month_min_temp ~ centroid.id + clim_year, data = clim, FUN = min) %>%
                  dplyr::rename(bio6 = month_min_temp)
      }
      #----
      
      
      
      # Annual Temperature Range - BIO7      ----
      #   -  Equal to the difference between the average monthly maximum daily temperature for the warmest month 
      #                                                     and the average monthly minimum daily temperature for the coldest month (BIO5 - BIO6)
      if (any(c(7, 3) %in% bioclim_indices)) {      # BIO3 Depends on BIO7 to be computed - therefore, we include this in the conditional
            
            # merging Bio5 and BIO6
            pre_bio7 <- merge(results_list[["5"]], results_list[["6"]], by = c("centroid.id", "clim_year"))
            
            # Computing bio7
            pre_bio7$bio7 <- pre_bio7$bio5 - pre_bio7$bio6
            
            # Saving the result
            results_list[["7"]] <- pre_bio7 %>%
                  dplyr::select(centroid.id, clim_year, bio7)
            
            # cleaning up environment
            rm(pre_bio7)
      }
      #----
      
      
      
      # Isothermality (The Daily Temperature Range Relative to Annual Temperature Range)  -  BIO3      ----
      #   -  Equal to the ratio of the mean annual diurnal range to the Annual temperature range (BIO2 / BIO7)
      if (3 %in% bioclim_indices) {
            
            # merging Bio5 and BIO6
            pre_bio3 <- merge(results_list[["2"]], results_list[["7"]], by = c("centroid.id", "clim_year"))
            
            # Computing bio7
            pre_bio3$bio3 <- (pre_bio3$bio2 / pre_bio3$bio7)*100
            
            # Saving the result
            results_list[["3"]] <- pre_bio3 %>%
                  dplyr::select(centroid.id, clim_year, bio3)
            
            # cleaning up environment
            rm(pre_bio3)
      }
      #----
      
      
      
      # Mean Average Daily Temperature of Wettest Quarter - BIO8      ----
      #   -  Equal to the quarterly mean of daily average temperature for the quarter of the year where precipitation was highest. 
      if (8 %in% bioclim_indices) {
            
            pre_bio8 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_tot_rain == max(q_tot_rain)) %>%
                  dplyr::summarise(q_av_temp = mean(q_av_temp), .groups = "drop")
            
            results_list[["8"]] <- pre_bio8 %>%
                  dplyr::rename(bio8 = q_av_temp)
            
            rm(pre_bio8)
      }
      #----
      
      
      
      
      # Mean Average Daily Temperature of driest Quarter - BIO9      ----
      #   -  Equal to the quarterly mean of daily average temperature for the quarter of the year where precipitation was lowest. 
      if (9 %in% bioclim_indices) {
            
            pre_bio9 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_tot_rain == min(q_tot_rain)) %>%
                  dplyr::summarise(q_av_temp = mean(q_av_temp), .groups = "drop")
            
            results_list[["9"]] <- pre_bio9 %>%
                  dplyr::rename(bio9 = q_av_temp)
            
            rm(pre_bio9)
      }
      #----
      
      
      
      
      # Mean Average Daily Temperature of Warmest Quarter - BIO10      ----
      #   -  Equal to the highest quarterly mean of daily average temperature. 
      if (10 %in% bioclim_indices) {
            
            pre_bio10 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_av_temp == max(q_av_temp)) %>%
                  dplyr::summarise(q_av_temp = mean(q_av_temp), .groups = "drop")
            
            results_list[["10"]] <- pre_bio10 %>%
                  dplyr::rename(bio10 = q_av_temp)
            
            rm(pre_bio10)
      }
      #----
      
      
      
      
      # Mean Average Daily Temperature of Coldest Quarter - BIO11      ----
      #   -  Equal to the lowest quarterly mean of daily average temperature. 
      if (11 %in% bioclim_indices) {
            
            pre_bio11 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_av_temp == min(q_av_temp)) %>%
                  dplyr::summarise(q_av_temp = mean(q_av_temp), .groups = "drop")
            
            results_list[["11"]] <- pre_bio11 %>%
                  dplyr::rename(bio11 = q_av_temp)
            
            rm(pre_bio11)
      }
      #----
      
      
      
      
      
      ############################################    PRECIPITATION  -  Indice Calculations    ##############################################
      
      # Total Annual Precipitation  -  BIO12      ----
      #   -  Equal to the annual sum of all daily precipitation. 
      if (12 %in% bioclim_indices) {
            
            results_list[["12"]] <- aggregate(precip ~ centroid.id + clim_year, data = clim, FUN = sum) %>%
                  dplyr::rename(bio12 = precip)
      }
      #----
      
      
      
      # Total Precipitation During Wettest Month  -  BIO13      ----
      #   -  Equal to the monthly sum of all daily precipitation during the month with the highest precipitation
      if (13 %in% bioclim_indices) {
            
            results_list[["13"]] <- aggregate(month_tot_rain ~ centroid.id + clim_year, data = clim, FUN = max) %>%
                  dplyr::rename(bio13 = month_tot_rain)
      }
      #----
      
      
      
      # Total Precipitation During Driest Month  -  BIO14      ----
      #   -  Equal to the monthly sum of all daily precipitation during the month with the lowest precipitation
      if (14 %in% bioclim_indices) {
            
            results_list[["14"]] <- aggregate(month_tot_rain ~ centroid.id + clim_year, data = clim, FUN = min) %>%
                  dplyr::rename(bio14 = month_tot_rain)
      }
      #----
      
      
      
      # Seasonality Index for Rainfall  -  BIO15      ----
      #   -  Equal to the Standard Deviation of Monthly totals of precipitation for the year, divided by the average monthly precipitation
      #                                         for the year (added to 1 to avoid strange negative index values), 
      #                                         multiplied by 100 to be expressed as a percentage.
      if (15 %in% bioclim_indices) {
            
            # computing the standard deviation in monthly total rainfall
            monthly_tot_rain_sd <- aggregate(month_tot_rain ~ centroid.id + clim_year, data = clim, FUN = sd) %>%
                  dplyr::rename(month_tot_rain_sd = month_tot_rain)
            
            # computing the yearly average of monthly average temp in Kelvin
            yearly_av_month_rain <- aggregate(month_tot_rain ~ centroid.id + clim_year, data = clim, FUN = mean) %>%
                  dplyr::rename(year_av_month_rain = month_tot_rain)
            
            # merging dataframes together
            tot_rain_cv <- merge(monthly_tot_rain_sd, yearly_av_month_rain, by = c("centroid.id", "clim_year"))
            
            # computing BIO4 - 
            tot_rain_cv$bio15 <- (tot_rain_cv$month_tot_rain_sd/tot_rain_cv$year_av_month_rain)*100
            
            # saving Result
            results_list[["15"]] <- tot_rain_cv %>%
                  dplyr::select(centroid.id, clim_year, bio15)
            
            # removing all objects:
            rm(monthly_tot_rain_sd, yearly_av_month_rain, tot_rain_cv)
      }
      #----
      
      
      
      # Precipitation for Wettest Quarter - BIO16      ----
      #   -  Equal to the total precipitation for the quarter (3 consecutive month period) with the highest total precipitation
      if (16 %in% bioclim_indices) {
            
            pre_bio16 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_tot_rain == max(q_tot_rain)) %>%
                  dplyr::summarise(q_tot_rain = mean(q_tot_rain), .groups = "drop")
            
            results_list[["16"]] <- pre_bio16 %>%
                  dplyr::rename(bio16 = q_tot_rain)
            
            rm(pre_bio16)
      }
      #----
      
      
      
      # Precipitation for the Driest Quarter - BIO17      ----
      #   -  Equal to the total precipitation for the quarter (3 consecutive month period) with the lowest total precipitation
      if (17 %in% bioclim_indices) {
            
            pre_bio17 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_tot_rain == min(q_tot_rain)) %>%
                  dplyr::summarise(q_tot_rain = mean(q_tot_rain), .groups = "drop")
            
            results_list[["17"]] <- pre_bio17 %>%
                  dplyr::rename(bio17 = q_tot_rain)
            
            rm(pre_bio17)
      }
      #----
      
      
      
      # Precipitation of Warmest Quarter  -  BIO18      ----
      #   -  Equal to the sum of precipitation for the warmest 3 months of the year. 
      if (18 %in% bioclim_indices) {
            
            pre_bio18 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_av_temp == max(q_av_temp)) %>%
                  dplyr::summarise(q_tot_rain = mean(q_tot_rain), .groups = "drop")
            
            results_list[["18"]] <- pre_bio18 %>%
                  dplyr::rename(bio18 = q_tot_rain)
            
            rm(pre_bio18)
      }
      #----
      
      
      
      # Precipitation of Warmest Quarter  -  BIO19      ----
      #   -  Equal to the sum of precipitation for the coldest 3 months of the year. 
      if (19 %in% bioclim_indices) {
            
            pre_bio19 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_av_temp == min(q_av_temp)) %>%
                  dplyr::summarise(q_tot_rain = mean(q_tot_rain), .groups = "drop")
            
            results_list[["19"]] <- pre_bio19 %>%
                  dplyr::rename(bio19 = q_tot_rain)
            
            rm(pre_bio19)
      }
      #----
      
      
      
      
      
      ############################################    RADIATION  -  Indice Calculations    ##############################################
      
      # Mean Annual Daily Radiation  -  BIO20      ----
      #   -  Equal to the annual average of daily radiation values. 
      if (20 %in% bioclim_indices) {
            
            results_list[["20"]] <- aggregate(rad ~ centroid.id + clim_year, data = clim, FUN = mean) %>%
                  dplyr::rename(bio20 = rad)
      }
      #----
      
      
      
      # Mean Monthly Daily Radiation for the Month with the Highest Mean Radiation  -  BIO21      ----
      #   -  Equal to the highest monthly average of daily radiation for the year. 
      if (21 %in% bioclim_indices) {
            
            results_list[["21"]] <- aggregate(month_av_rad ~ centroid.id + clim_year, data = clim, FUN = max) %>%
                  dplyr::rename(bio21 = month_av_rad)
      }
      #----
      
      
      
      # Mean Monthly Daily Radiation for the Month with the lowest Mean Radiation  -  BIO22      ----
      #   -  Equal to the lowest monthly average of daily radiation for the year. 
      if (22 %in% bioclim_indices) {
            
            results_list[["22"]] <- aggregate(month_av_rad ~ centroid.id + clim_year, data = clim, FUN = min) %>%
                  dplyr::rename(bio22 = month_av_rad)
      }
      #----
      
      
      
      # Radiation seasonality  -  BIO23      ----
      #   -  Equal to the coefficient of variance for the monthly means daily radiation for the year. 
      if (23 %in% bioclim_indices) {
            
            # computing the standard deviation in monthly total rainfall
            monthly_av_rad_sd <- aggregate(month_av_rad ~ centroid.id + clim_year, data = clim, FUN = sd) %>%
                  dplyr::rename(month_av_rad_sd = month_av_rad)
            
            # computing the yearly average of monthly average temp in Kelvin
            yearly_av_month_rad <- aggregate(month_av_rad ~ centroid.id + clim_year, data = clim, FUN = mean) %>%
                  dplyr::rename(year_av_month_rad = month_av_rad)
            
            # merging dataframes together
            av_rad_cv <- merge(monthly_av_rad_sd, yearly_av_month_rad, by = c("centroid.id", "clim_year"))
            
            # computing BIO4 - 
            av_rad_cv$bio23 <- (av_rad_cv$month_av_rad_sd/av_rad_cv$year_av_month_rad)*100
            
            # saving Result
            results_list[["23"]] <- av_rad_cv %>%
                  dplyr::select(centroid.id, clim_year, bio23)
            
            # removing all objects:
            rm(monthly_av_rad_sd, yearly_av_month_rad, av_rad_cv)
      }
      #----
      
      
      
      # Mean Quarterly Radiation for the Wettest Quarter  -  BIO24      ----
      #   -  Equal to the quarterly mean of daily radiation for the quarter with the highest quarterly total rainfall. 
      if (24 %in% bioclim_indices) {
            
            pre_bio24 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_tot_rain == max(q_tot_rain)) %>%
                  dplyr::summarise(q_av_rad = mean(q_av_rad), .groups = "drop")
            
            results_list[["24"]] <- pre_bio24 %>%
                  dplyr::rename(bio24 = q_av_rad)
            
            rm(pre_bio24)
      }
      #----
      
      
      
      # Mean Quarterly Radiation for the Driest Quarter  -  BIO25      ----
      #   -  Equal to the quarterly mean of daily radiation for the quarter with the lowest quarterly total rainfall. 
      if (25 %in% bioclim_indices) {
            
            pre_bio25 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_tot_rain == min(q_tot_rain)) %>%
                  dplyr::summarise(q_av_rad = mean(q_av_rad), .groups = "drop")
            
            results_list[["25"]] <- pre_bio25 %>%
                  dplyr::rename(bio25 = q_av_rad)
            
            rm(pre_bio25)
      }
      #----
      
      
      
      # Mean Quarterly Radiation for the Warmest Quarter  -  BIO26      ----
      #   -  Equal to the quarterly mean of daily radiation for the quarter with the highest quarterly mean of daily average temperature. 
      if (26 %in% bioclim_indices) {
            
            pre_bio26 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_av_temp == max(q_av_temp)) %>%
                  dplyr::summarise(q_av_rad = mean(q_av_rad), .groups = "drop")
            
            results_list[["26"]] <- pre_bio26 %>%
                  dplyr::rename(bio26 = q_av_rad)
            
            rm(pre_bio26)
      }
      #----
      
      
      
      # Mean Quarterly Radiation for the Coldest Quarter  -  BIO27      ----
      #   -  Equal to the quarterly mean of daily radiation for the quarter with the lowest quarterly mean of daily average temperature.
      if (27 %in% bioclim_indices) {
            
            pre_bio27 <- quarter_stats %>%
                  dplyr::group_by(centroid.id, clim_year) %>%
                  dplyr::filter(q_av_temp == min(q_av_temp)) %>%
                  dplyr::summarise(q_av_rad = mean(q_av_rad), .groups = "drop")
            
            results_list[["27"]] <- pre_bio27 %>%
                  dplyr::rename(bio27 = q_av_rad)
            
            rm(pre_bio27)
      }
      #----
      
      
      ############################################    Compiling Results    ##############################################
      
      
      # Message if No Indices Calculated    ----
      if (length(results_list) == 0) {
            stop("No indices computed. Check bioclim_indices argument.")
      }
      #----
      
      
      
      # Binding all dataframes together and Saving    ----
      results_df <- results_list %>% purrr::reduce(full_join, by = c("centroid.id", "clim_year"))
      
      
      
      # Selecting collumns to retain based on user selection:
      requested_cols <- paste0("bio", bioclim_indices)
      
      
      # Selecting only requested collumns to remain in the dataframe:
      results_df <- results_df %>%
            dplyr::select(centroid.id, clim_year, all_of(requested_cols))
      #----
      
      
      # Averging by the user defined arguments  ----
      
      if(av_period_by == 1) {
            
            # Saving the Object
            saveRDS(results_df, file = output_directory)
            
            # Return Results
            return(results_df) 
            
            
      } else if (av_period_by < 1) {
            
            message(paste0("WARNING: Averaging Period Cannot be Less than 1", "\n", "Returning Results with av_period_by = 1"))
            
            
            # Saving the Object
            saveRDS(results_df, file = output_directory)
            
            # Return Results
            return(results_df) 
            
            
            
      } else if (av_period_by > 1) {
            
            
            # Assign each year to an averaging block
            results_df <- results_df %>%
                  dplyr::mutate(period_floor = floor((clim_year - av_period_start) / av_period_by) * av_period_by + av_period_start) %>%
                  dplyr::filter(clim_year >= av_period_start, clim_year <= av_period_end)
            
            
            # Averaging for within each centroid and time block:
            final_centroid_bioclim_df <- results_df %>%
                  dplyr::group_by(centroid.id, period) %>%
                  dplyr::summarise(across(starts_with("bio"), \(x) mean(x, na.rm = TRUE)), .groups = "drop")
            
            
            # Saving the Object
            saveRDS(final_centroid_bioclim_df, file = output_directory)
            
            # Return Results
            return(final_centroid_bioclim_df) 
      }
      #----
      
}


########################################################




##                   Example Syntax:                  ##
########################################################


# test_compile.raster <- readRDS("github/compiled_raster_clim_df.RDS")
# 
# 
# test_centroid_bioclim <- compute_centroid_bioclims(centroid_clim.data = test_compile.raster,
#                                                    bioclim_indices = c(2, 3, 12, 23),
#                                                    var.names = c("tmin", "tmax", "daily_rain", "radiation"),
#                                                    av_period_start = 2019,
#                                                    av_period_end = 2020,
#                                                    av_period_by = 1, 
#                                                    output_directory = "github/test_centroid_compute_bioclim.RDS")


########################################################




































