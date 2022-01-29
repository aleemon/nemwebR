#' Retrieve archived DUDETAILSUMMARY data
#'
#' This function returns one month of DUDETAILSUMMARY data from AEMO's NEMWeb as specified by the datestring argument
#'
#' DUDETAILSUMMARY data contains historical DUID registration details for all registered generators in the NEM.
#'
#' Archive data is available from July 2009 to approximately two weeks ago. In order to retrieve newer data you will need to use the nemwebR_current_DUDETAILSUMMARY function.
#'
#'
#' @param datestring integer of the form YYYYMM
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_dudetailsummary(202101)
#'
nemwebR_archive_dudetailsummary <- function(datestring) {

  temp <- tempfile()
  utils::download.file(url = stringr::str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    stringr::str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    stringr::str_sub(datestring, start = 1, end = 4),
    "_",
    stringr::str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_DUDETAILSUMMARY_",
    datestring,
    "010000.zip"),
    destfile = temp, mode = "wb", quiet = TRUE)


  data_file <- utils::read.csv(utils::unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(stringr::str_c(
    "PUBLIC_DVD_DUDETAILSUMMARY_",
    datestring,
    "010000.csv")
  )


  colnames(data_file) <- data_file[2, ]
  data_file <- data_file[-c(1:2), -c(1:4)]
  data_file <- utils::head(data_file, -1)


  data_file$START_DATE <- as.POSIXct(data_file$START_DATE,
                                     tz = "Australia/Brisbane",
                                     format = "%Y/%m/%d %H:%M:%S")

  data_file$END_DATE <- as.POSIXct(data_file$END_DATE,
                                   tz = "Australia/Brisbane",
                                   format = "%Y/%m/%d %H:%M:%S")

  data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
                                      tz = "Australia/Brisbane",
                                      format = "%Y/%m/%d %H:%M:%S")


  ## Older files only have 19 columns, the newer files have 24 columns. At least the column names are consistent
  ## Check if all columns exist, add dummy columns into the data
  missing_columns <- setdiff(
    c("MIN_RAMP_RATE_UP", "MIN_RAMP_RATE_DOWN", "MAX_RAMP_RATE_UP", "MAX_RAMP_RATE_DOWN", "IS_AGGREGATED"),
    colnames(data_file)
  )

  if(length(missing_columns != 0)) {
    data_file[ , missing_columns] <- NA
  }


  data_file <- data_file %>% dplyr::mutate(
    dplyr::across(
      .cols = c(TRANSMISSIONLOSSFACTOR, DISTRIBUTIONLOSSFACTOR, MINIMUM_ENERGY_PRICE, MAXIMUM_ENERGY_PRICE,
                MIN_RAMP_RATE_UP, MIN_RAMP_RATE_DOWN, MAX_RAMP_RATE_UP, MAX_RAMP_RATE_DOWN, IS_AGGREGATED),
      .fns = as.numeric
      )
    )


  ## Old code:
  #data_file <- data_file %>% dplyr::mutate(dplyr::across(.cols = c(10, 12:14, 16:20), .fns = as.numeric))


  ## Filter for current units only
  data_file <- dplyr::filter(data_file, END_DATE > lubridate::ymd(datestring))


  return(data_file)

}
