#' Retrieve archived GENUNITS data
#'
#' This function returns one month of GENUNITS data from AEMO's NEMWeb as specified by the datestring argument
#'
#' GENUNITS data contains historical generation unit registration details, including fuel type and CO2 emissions information.
#'
#' Archive data is available from July 2009 to approximately two weeks ago. In order to retrieve newer data you will need to use the nemwebR_current_GENUNITS function.
#'
#'
#' @param datestring integer of the form YYYYMM
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_dispatch_genunits(202101)
#'
nemwebR_archive_genunits <- function(datestring) {

  temp <- tempfile()
  utils::download.file(url = stringr::str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    stringr::str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    stringr::str_sub(datestring, start = 1, end = 4),
    "_",
    stringr::str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_GENUNITS_",
    datestring,
    "010000.zip"),
    destfile = temp, mode = "wb", quiet = TRUE)


  data_file <- utils::read.csv(utils::unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(stringr::str_c(
    "PUBLIC_DVD_GENUNITS_",
    datestring,
    "010000.csv")
  )


  colnames(data_file) <- data_file[2, ]
  data_file <- data_file[-c(1:2), -c(1:4)]
  data_file <- utils::head(data_file, -1)


  ## Remove deprecated columns
  data_file <- data_file %>% dplyr::select(!c(SETLOSSFACTOR, SPINNINGFLAG))


  ## Correct data types
  data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
                                      tz = "Australia/Brisbane",
                                      format = "%Y/%m/%d %H:%M:%S")

  data_file <- data_file %>%
    dplyr::mutate(dplyr::across(.cols = c(VOLTLEVEL, REGISTEREDCAPACITY, MAXCAPACITY, CO2E_EMISSIONS_FACTOR),
                                .fns = as.numeric))


  return(data_file)

}
