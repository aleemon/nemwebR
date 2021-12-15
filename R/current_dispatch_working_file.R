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


  ## Test for end date in the future, effectively
  } else if (
    any(stringr::str_detect(current_files, as.character(stringr::str_c(end_date, "0000")))) == FALSE &
    any(stringr::str_detect(archive_files, as.character(stringr::str_c(end_date, "0000")))) == FALSE
    ) {

    stop("End date falls outside of the Current Reports data range. Please choose a date prior to today.")

  ## Case 1/3: Start date in current, end date in current (this case is most unlikely)
  } else if (
    any(stringr::str_detect(current_files, pattern = as.character(stringr::str_c(start_date, "0005")))) &
    any(stringr::str_detect(current_files, pattern = as.character(stringr::str_c(end_date))))
  ) {

    ## Note that this will just fetch all data from the specified start date to the most recent available data

    date_range <- format(
      seq(
        ISOdatetime(
          stringr::str_sub(start_date, start = 1, end = 4),
          stringr::str_sub(start_date, start = 5, end = 6),
          stringr::str_sub(start_date, start = 7, end = 8),
          0, 0, 0,
          tz = "GMT"),
        ISOdatetime(
          stringr::str_sub(end_date, start = 1, end = 4),
          stringr::str_sub(end_date, start = 5, end = 6),
          stringr::str_sub(end_date + 1, start = 7, end = 8),
          0, 0, 0,
          tz = "GMT"),
        by = (60 * 5)
        ),
      "%Y%m%d%H%M",
      tz = "GMT"
      )

    ## Get ride of the start_date + 0000 from the vector of dates
    date_range <- date_range[date_range != as.character(stringr::str_c(start_date, "0000"))]


    ## Find which of the dates don't exist in the current files, strip them out
    current_dates <- stringr::str_remove_all(
      current_files,
      pattern = "/Reports/CURRENT/DispatchIS_Reports/PUBLIC_DISPATCHIS_"
      ) %>% stringr::str_remove_all(pattern = "(_[:digit:]+.zip)")

    ## Subset
    date_range <- date_range[date_range %in% current_dates]


    ## Now run the train on the loop! Easy right!

    # Define a function, map it through the list.

    datdata <- map_dfr(
      date_range,
      function(x) {

        # download file and unzip etc in here (should be simpler than archive case)

        # Might still require a read_lines() approach?

        }
      )













  ## Case 2/3: Start date in archive, end date in current
  } else if (
    any(stringr::str_detect(archive_files, pattern = as.character(start_date))) &
    any(stringr::str_detect(current_files, pattern = as.character(stringr::str_c(end_date + 1, "0000"))))
  ) {

    ## Do different stuff

    # Find where the current date ends, round up - generate two different sequences
    # Loop through

    # See approach above for defining the date vector








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
      utils::download.file(archive_url, destfile = temp_file, mode = "wb") #, quiet = TRUE)
      file_names <- unzip(temp_file, list = TRUE)$Name

      ## Map across vectors of 5-min zip files inside day zip file
      data_list[[i]] <- purrr::map_dfr(file_names, function(x) {

        datdata <- readr::read_lines(
          utils::unzip(
            utils::unzip(temp_file, x),
            stringr::str_replace(x, ".zip", ".CSV")
          )
        )

        datdata <- purrr::map(datdata, function(x) {stringr::str_split(x, pattern = ",", simplify = TRUE) })
        datdata <- datdata[purrr::map(datdata, length) == 60] # Price data is 60 columns across
        datdata <- do.call(rbind, datdata)
        colnames(datdata) <- datdata[1, ]
        datdata <- as.data.frame(datdata)
        datdata <- datdata[-1, -c(1:4)]

        }
      )

      ## Dump all the files
      unlink(temp_file)
      unlink(file_names) # Dump all zip files
      unlink(stringr::str_replace_all(file_names, ".zip", ".CSV")) # Dump all csv files


      ## read_lines() introduced random inverted commas in the date formats
      data_list[[i]]$SETTLEMENTDATE <- stringr::str_remove_all(
        data_list[[i]]$SETTLEMENTDATE, pattern = "^\"") # Remove the starting "
      data_list[[i]]$SETTLEMENTDATE <- stringr::str_remove_all(
        data_list[[i]]$SETTLEMENTDATE, pattern = "\"$") # Remove the ending "

      data_list[[i]]$LASTCHANGED <- stringr::str_remove_all(
        data_list[[i]]$LASTCHANGED, pattern = "^\"") # Remove the starting "
      data_list[[i]]$LASTCHANGED <- stringr::str_remove_all(
        data_list[[i]]$LASTCHANGED, pattern = "\"$") # Remove the ending "


      ## Fix the date formatting
      data_list[[i]]$SETTLEMENTDATE <- as.POSIXct(data_list[[i]]$SETTLEMENTDATE,
                                                  tz = "Australia/Brisbane",
                                                  format = "%Y/%m/%d %H:%M:%S")

      data_list[[i]]$LASTCHANGED <- as.POSIXct(data_list[[i]]$LASTCHANGED,
                                                  tz = "Australia/Brisbane",
                                                  format = "%Y/%m/%d %H:%M:%S")


      data_list[[i]] <- data_list[[i]] %>%
        dplyr::mutate(dplyr::across(.cols = c(2, 4:10, 12:35, 37:54), .fns = as.numeric))

      ## Correct the intervention naming This is the little cunt.
      data_list[[i]] <- data_list[[i]] %>% dplyr::group_by(REGIONID, SETTLEMENTDATE) %>%
        dplyr::slice(which.min(INTERVENTION)) %>% dplyr::ungroup()

    } # End date range for loop

    data_file <- do.call(dplyr::bind_rows, data_list)


    return(data_file)


  } # End last else if loop

} # End function


sdate <- 20211102
edate <- 20211104

test_data <- nemwebR_current_dispatchprice(sdate, edate)
