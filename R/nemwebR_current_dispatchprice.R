#' Retrieve current DISPATCHPRICE data
#'
#' This function returns DISPATCHPRICE data from AEMO's NEMWeb as specified by the start and end date arguments.
#'
#' DISPATCHPRICE data contains 5-minute regional pricing data for energy and FCAS markets.
#'
#' Current data is available from yesterday to approximately two months ago. In order to retrieve older data you will need to use the `nemwebR_archive_dispatchprice()` function.
#'
#' @param start_date integer of the form YYYYMMDD
#' @param end_date integer of the form YYYYMMDD
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_current_dispatchprice(20210101, 20210131)
#'
#'

#! Full dispatch price data is stored in the current and archive reports
#! Rewrite the function to fetch from the archive reports too, will need to do a lot more cleaning, because files are
#   batched inside of the zip files



#! Limit how far back the function will fetch, because it will be so slow.

# Function will need to find the earliest file in the current reports
  # compare that to the start date
  # Round up to the next full day (likely yesterday)
  # Go to the archive reports and fetch
  # Archive reports appear to be two days lagging, so basically just go there quickly should be minimal-ish overlap.

nemwebR_current_dispatchprice <- function(start_date, end_date) {

  ## Extract a list of files in the Current Reports sub-directory
  current_files <- rvest::html_attr(
    rvest::html_elements(
      rvest::read_html("http://nemweb.com.au/Reports/CURRENT/DispatchIS_Reports/"),
      "a"),
    "href"
    )

  ## Extract a list of files in the Archive Reports sub-directory
  archive_files <- rvest::html_attr(
    rvest::html_elements(
      rvest::read_html("http://nemweb.com.au/Reports/ARCHIVE/DispatchIS_Reports/"),
      "a"),
    "href"
    )

  ## Generate a sequence of dates between the start and end
  #date_range <- seq.Date(from = lubridate::ymd(start_date), to = lubridate::ymd(end_date), by = "days")

#! Probably don't need this - because the date range sequences are created within each of the cases below

  ## Add a day at the start to capture the midnight to 4am window
#! Not needed because th reports are done in 5-min blocks
  # date_range <- c(
  #   stringr::str_c(
  #     lubridate::year(
  #       lubridate::ymd(start_date) - 1
  #     ),
  #     stringr::str_pad(
  #       lubridate::month(
  #         lubridate::ymd(start_date) - 1
  #       ),
  #       width = 2, side = "left", pad = "0"
  #     ),
  #     stringr::str_pad(
  #       lubridate::day(
  #         lubridate::ymd(start_date) - 1
  #       ),
  #       width = 2, side = "left", pad = "0"
  #     )
  #   ),
  #   date_range
  #   )


#! Alt approach - define two vectors, archive_start : archive_end and current_start : current_end

  ## Still need to the check below, but put this logic in a nested else if loop



  ## Test if start date is contained in the archive reports
  if(any(stringr::str_detect(archive_files, as.character(start_date))) != TRUE) {

    stop("Start date falls outside of the Archive Reports data range. Latest date is: ",
         lubridate::ymd(
           str_remove(
             str_remove(
               utils::head(rvest::html_attr(
                 rvest::html_elements(
                   rvest::read_html("http://nemweb.com.au/Reports/ARCHIVE/DispatchIS_Reports/"),
                   "a"),
                 "href"
                 ),
                 n = 2)[2],
               pattern = "/Reports/ARCHIVE/DispatchIS_Reports/PUBLIC_DISPATCHIS_"
             ),
             pattern = ".zip"
           )
         ),
         ". Try using `nemwebR_archive_dispatchprice()`"
         )


  ## Test if the end date is within current reports - this test should actually be rewritten
  } else if (any(stringr::str_detect(current_files, as.character(stringr::str_c(end_date, "0000")))) == TRUE) {

    stop("End date falls outside of the Current Reports data range. Please choose a date prior to today.")

  ## Case 1/3: Start date in current, end date in current (this case is most unlikely)
  } else if (
    any(stringr::str_detect(current_files, pattern = as.character(stringr::str_c(start_date, "0005")))) &
    any(stringr::str_detect(current_files, pattern = as.character(stringr::str_c(end_date + 1, "0000"))))
  ) {

    ## Do stuff - round the start date down to 0005, round end date up to + 1 & 0000
    # Create seq of dates
    # Loop dates through and combine all the files
















  ## Case 2/3: Start date in archive, end date in current
  } else if (
    any(stringr::str_detect(archive_files, pattern = as.character(start_date))) &
    any(stringr::str_detect(current_files, pattern = as.character(stringr::str_c(end_date + 1, "0000"))))
  ) {

    ## Do different stuff

    # Find where the current date ends, round up - generate two different sequences
    # Loop through










  ## Case 3/3: Start date in archive, end date in archive
  } else if (
    any(stringr::str_detect(archive_files, pattern = as.character(start_date))) &
    any(stringr::str_detect(archive_files, pattern = as.character(end_date + 1)))
    ) {

    date_range <- seq.Date(
      from = as.Date(lubridate::ymd(start_date)),
      to = as.Date(lubridate::ymd(end_date)),
      by = "day"
      ) %>% stringr::str_remove_all("-")


    data_list <- list()

    for (i in 1:length(date_range)) {

      archive_url <- stringr::str_c(
        "http://nemweb.com.au/Reports/archive/DispatchIS_Reports/PUBLIC_DISPATCHIS_",
        date_range[i],
        ".zip"
      )

      ## Download the day zip file
      temp_file <- tempfile()
      utils::download.file(archive_url, destfile = temp_file, mode = "wb", quiet = TRUE)
      file_names <- unzip(temp_file, list = TRUE)$Name

      ## Map across vectors of 5-min zip files inside day zip file
      data_list[[i]] <- purrr::map_dfr(file_names, function(file_name) {

        datdata <- readr::read_lines(
          utils::unzip(
            utils::unzip(temp_file, file_name),
            stringr::str_replace(file_name, ".zip", ".CSV")
            )
          )

        datdata <- map(datdata, function(x) {str_split(x, pattern = ",", simplify = TRUE) })
        datdata <- datdata[map(datdata, length) == 60] # Price data is 60 columns across
        datdata <- do.call(rbind, datdata)
        colnames(datdata) <- datdata[1, ]
        datdata <- as.data.frame(datdata)
        datdata <- datdata[-1, -c(1:4)]

      } # End unnamed download function

      )

      ## Dump the temp file
      unlink(temp_file)

      ##  Explicitly dump all of the files
      unlink(file_names) # Dump all zip files
      unlink(stringr::str_replace_all(file_names, ".zip", ".CSV")) # Dump all csv files




      ## Tidy up the data
      # data_list[[i]] <- data_list[[i]][, -3]
      # data_list[[i]] <- dplyr::filter(data_list[[i]], V2 == "DREGION", V4 == 3) # Filter for just dispatch prices
      # colnames(data_list[[i]]) <- data_list[[i]][1, ]
      # data_list[[i]] <- data_list[[i]][-1, -c(1:3)]

      #! Check these columns still valid - remove more columns, keep it inline with dispatch_price
      #! Doesn't have all the dispatch price columns - fuckers!

      ## Filter out unwanted columns
      data_list[[i]] <- data_list[[i]] %>% dplyr::select(
        !c(LOWER5MINDISPATCH, LOWER5MINIMPORT, LOWER5MINLOCALPRICE, LOWER5MINLOCALREQ, LOWER5MINPRICE, LOWER5MINREQ, LOWER5MINSUPPLYPRICE,
           LOWER60SECDISPATCH, LOWER60SECIMPORT, LOWER60SECLOCALPRICE, LOWER60SECLOCALREQ, LOWER60SECPRICE, LOWER60SECREQ, LOWER60SECSUPPLYPRICE,
           LOWER6SECDISPATCH, LOWER6SECIMPORT, LOWER6SECLOCALPRICE, LOWER6SECLOCALREQ, LOWER6SECPRICE, LOWER6SECREQ, LOWER6SECSUPPLYPRICE,
           RAISE5MINDISPATCH, RAISE5MINIMPORT, RAISE5MINLOCALPRICE, RAISE5MINLOCALREQ, RAISE5MINPRICE, RAISE5MINREQ, RAISE5MINSUPPLYPRICE,
           RAISE60SECDISPATCH, RAISE60SECIMPORT, RAISE60SECLOCALPRICE, RAISE60SECLOCALREQ, RAISE60SECPRICE, RAISE60SECREQ, RAISE60SECSUPPLYPRICE,
           RAISE6SECDISPATCH, RAISE6SECIMPORT, RAISE6SECLOCALPRICE, RAISE6SECLOCALREQ, RAISE6SECPRICE, RAISE6SECREQ, RAISE6SECSUPPLYPRICE,
           LOWERREGIMPORT, LOWERREGLOCALREQ, LOWERREGREQ, RAISEREGIMPORT, RAISEREGLOCALREQ, RAISEREGREQ,
           RAISE5MINLOCALVIOLATION, RAISEREGLOCALVIOLATION, RAISE60SECLOCALVIOLATION, RAISE6SECLOCALVIOLATION,
           LOWER5MINLOCALVIOLATION, LOWERREGLOCALVIOLATION, LOWER60SECLOCALVIOLATION, LOWER6SECLOCALVIOLATION,
           RAISE5MINVIOLATION, RAISEREGVIOLATION, RAISE60SECVIOLATION, RAISE6SECVIOLATION,
           LOWER5MINVIOLATION, LOWERREGVIOLATION, LOWER60SECVIOLATION, LOWER6SECVIOLATION
        )
      )

      data_list[[i]]$SETTLEMENTDATE <- as.POSIXct(data_list[[i]]$SETTLEMENTDATE,
                                             tz = "Australia/Brisbane",
                                             format = "%Y/%m/%d %H:%M:%S")


      data_list[[i]] <- data_list[[i]] %>% dplyr::mutate(dplyr::across(.cols = c(2, 4:7, 9:25), .fns = as.numeric))

      ## Correct the intervention naming (could introduce unwanted grouping?)
      data_list[[i]] <- data_list[[i]] %>% dplyr::group_by(REGIONID, SETTLEMENTDATE) %>%
        dplyr::slice(which.min(INTERVENTION)) %>% dplyr::ungroup()

    } # End date range for loop

    data_file <- do.call(dplyr::bind_rows, data_list)

    ## Trim data to midnight start and ends - not needed for archive reports
    # data_file <- dplyr::filter(data_file,
    #                            SETTLEMENTDATE >= lubridate::ymd(start_date),
    #                            SETTLEMENTDATE
    # )


    return(data_file)


  } # End last else if loop

} # End function




















##-----  test code -----

  ## Working code for read_lines approach, has been incoporated above:
  # price_data <- readr::read_lines(here::here("PUBLIC_DISPATCHIS_202111030005_0000000351927546.CSV"))
  # price_data <- map(price_data, function(x) {str_split(x, pattern = ",", simplify = TRUE) })
  # price_data <- test_dataframe[map(price_data, length) == 60] # Price data is 60 columns across
  # price_data <- do.call(rbind, price_data)
  # colnames(price_data) <- price_data[1, ]
  # price_data <- as.data.frame(price_data)
  # price_data <- price_data[-1, -c(1:4)]

  ## Then fix data types


##-----  Old code  -----
#! Most of the code below is now wrong, modify and work into the 3 cases as above

    data_list <- list()

    for (i in 1:length(date_range)) {

      temp <- tempfile()

      utils::download.file(url = stringr::str_c(
        "http://nemweb.com.au",
        file_names[stringr::str_detect(file_names, stringr::str_c(datestring, "0000")) == TRUE]),
        destfile = temp, mode = "wb")

        data_list[[i]] <- utils::read.csv(utils::unzip(temp), header = FALSE)

        ## Dump the files from the hard drive
        unlink(temp)

        unlink(
          stringr::str_c(
            stringr::str_split(
              stringr::str_split(
                file_names[stringr::str_detect(file_names, stringr::str_c(datestring, "0000")) == TRUE],
                "/Reports/Current/Public_Prices/",
                simplify = TRUE)[1, 2],
              ".zip",
              simplify = TRUE)[1, 1],
            ".CSV"
            )
          )

          ## Tidy up the data
          data_list[[i]] <- data_list[[i]][, -3]
          data_list[[i]] <- dplyr::filter(data_list[[i]], V2 == "DREGION", V4 == 3) # Filter for just dispatch prices
          colnames(data_list[[i]]) <- data_list[[i]][1, ]
          data_list[[i]] <- data_list[[i]][-1, -c(1:3)]

#! Check these columns still valid - remove more columns, keep it inline with dispatch_price
#! Doesn't have all the dispatch price columns - fuckers!

          ## Filter out unwanted columns
          data_list[[i]] <- data_list[[i]] %>% dplyr::select(
            !c(LOWER5MINDISPATCH, LOWER5MINIMPORT, LOWER5MINLOCALPRICE, LOWER5MINLOCALREQ, LOWER5MINPRICE, LOWER5MINREQ, LOWER5MINSUPPLYPRICE,
               LOWER60SECDISPATCH, LOWER60SECIMPORT, LOWER60SECLOCALPRICE, LOWER60SECLOCALREQ, LOWER60SECPRICE, LOWER60SECREQ, LOWER60SECSUPPLYPRICE,
               LOWER6SECDISPATCH, LOWER6SECIMPORT, LOWER6SECLOCALPRICE, LOWER6SECLOCALREQ, LOWER6SECPRICE, LOWER6SECREQ, LOWER6SECSUPPLYPRICE,
               RAISE5MINDISPATCH, RAISE5MINIMPORT, RAISE5MINLOCALPRICE, RAISE5MINLOCALREQ, RAISE5MINPRICE, RAISE5MINREQ, RAISE5MINSUPPLYPRICE,
               RAISE60SECDISPATCH, RAISE60SECIMPORT, RAISE60SECLOCALPRICE, RAISE60SECLOCALREQ, RAISE60SECPRICE, RAISE60SECREQ, RAISE60SECSUPPLYPRICE,
               RAISE6SECDISPATCH, RAISE6SECIMPORT, RAISE6SECLOCALPRICE, RAISE6SECLOCALREQ, RAISE6SECPRICE, RAISE6SECREQ, RAISE6SECSUPPLYPRICE,
               LOWERREGIMPORT, LOWERREGLOCALREQ, LOWERREGREQ, RAISEREGIMPORT, RAISEREGLOCALREQ, RAISEREGREQ,
               RAISE5MINLOCALVIOLATION, RAISEREGLOCALVIOLATION, RAISE60SECLOCALVIOLATION, RAISE6SECLOCALVIOLATION,
               LOWER5MINLOCALVIOLATION, LOWERREGLOCALVIOLATION, LOWER60SECLOCALVIOLATION, LOWER6SECLOCALVIOLATION,
               RAISE5MINVIOLATION, RAISEREGVIOLATION, RAISE60SECVIOLATION, RAISE6SECVIOLATION,
               LOWER5MINVIOLATION, LOWERREGVIOLATION, LOWER60SECVIOLATION, LOWER6SECVIOLATION
               )
            )

            data_file$SETTLEMENTDATE <- as.POSIXct(data_file$SETTLEMENTDATE,
                                                   tz = "Australia/Brisbane",
                                                    format = "%Y/%m/%d %H:%M:%S")


            data_file <- data_file %>% dplyr::mutate(dplyr::across(.cols = c(2, 4:7, 9:25), .fns = as.numeric))

            ## Correct the intervention naming (could introduce unwanted grouping?)
            data_file <- data_file %>% dplyr::group_by(REGIONID, SETTLEMENTDATE) %>%
              dplyr::slice(which.min(INTERVENTION)) %>% dplyr::ungroup()

          }

    data_file <- do.call(dplyr::bind_rows, data_list)

    ## Trim data to midnight start and ends
    data_file <- dplyr::filter(data_file,
                               SETTLEMENTDATE >= lubridate::ymd(start_date),
                               SETTLEMENTDATE
                               )


    return(data_file)






## Functioning code of unzipping zip inside zip


archive_url <- "http://nemweb.com.au/Reports/archive/DispatchIS_Reports/PUBLIC_DISPATCHIS_20210501.zip"
temp_file <- tempfile()
utils::download.file(archive_url, destfile = temp_file, mode = "wb", quiet = TRUE)
file_names <- unzip(temp_file, list = TRUE)$Name

datdata_all <- purrr::map_dfr(file_names, function(file_name) {

  datdata <- read.csv(
    utils::unzip(
      utils::unzip(temp_file, file_name),
      stringr::str_replace(file_name, ".zip", ".CSV")
    ),
    header = FALSE
  )

}

)


unlink(temp_file)

#! Then explicitly dump the files






#! Add in filtering to remove unwanted data

datdata <- filter(datdata_all, V2 == "DISPATCH", V2 == "PRICE") # Why doesn't this work?



