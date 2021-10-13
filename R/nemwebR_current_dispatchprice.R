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
  date_range <- seq.Date(from = lubridate::ymd(start_date), to = lubridate::ymd(end_date), by = "days")

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


  str_detect(current_files, as.character(stringr::str_c(start_date, 0005)))



  ## Test if start date is contained in the archive reports
  if(all(stringr::str_detect(archive_files, as.character(start_date))) == TRUE) {

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

#! Test if the end date is within current reports - this test should actually be rewritten
  } else if (all(stringr::str_detect(current_files, as.character(stringr::str_c(end_date, "0000")))) == TRUE) {

    stop("End date falls outside of the Current Reports data range. Please choose a date prior to today.")

#! Display the most recent data in the error message

  ## Case 1/3: Start date in archive, end date in archive
  } else if (
    all(stringr::str_detect(current_files, as.character(stringr::str_c(start_date, "0005")))) == TRUE &
    all(stringr::str_detect(current_files, as.character(stringr::str_c(end_date, "0000")))) == TRUE) {


    ## Do stuff - this should be one of the simpler cases

    temp <- tempfile()

    utils::download.file(url = stringr::str_c(
      "http://nemweb.com.au",
      file_names[stringr::str_detect(file_names, stringr::str_c(datestring, "0000")) == TRUE]),
      destfile = temp, mode = "wb")

    data_list[[i]] <- utils::read.csv(utils::unzip(temp), header = FALSE)




  ## Case 2/3: Start date in archive, end date in current
  } else if (
    all(stringr::str_detect(current_files, as.character(stringr::str_c(start_date, "0005")))) == TRUE &
    all(stringr::str_detect(archive_files, as.character(end_date))) == TRUE) {


    ## Do different stuff


  ## Case 3/3: Start date in current, end date in current (unlikely)
  } else if (
    all(stringr::str_detect(archive_files, as.character(start_date))) == TRUE &
    all(stringr::str_detect(archive_files, as.character(end_date))) == TRUE) {



    ## Do differenter stuff


  }





#! Most of the code below is now wrong,

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


}
