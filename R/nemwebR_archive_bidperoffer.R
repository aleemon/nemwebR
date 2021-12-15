#' Retrieve archived BIDPEROFFER data
#'
#' This function returns one month of BIDPEROFFER data from AEMO's NEMWeb as specified by the datestring argument
#'
#' BIDPEROFFER data contains bid energy and FCAS volumes for all scheduled and non-scheduled generators in the NEM.
#'
#' Archive data is available from July 2009 to approximately two weeks ago. In order to retrieve newer data you will need to use the nemwebR_current_BIDPEROFFER function.
#'
#'
#' @param datestring integer of the form YYYYMM
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_bidperoffer(202101)
#'
nemwebR_archive_bidperoffer <- function(datestring) {

  temp <- tempfile()
  utils::download.file(url = stringr::str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    stringr::str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    stringr::str_sub(datestring, start = 1, end = 4),
    "_",
    stringr::str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_BIDPEROFFER_",
    datestring,
    "010000.zip"),
    destfile = temp, mode = "wb", quiet = TRUE)


  data_file <- utils::read.csv(utils::unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(stringr::str_c(
    "PUBLIC_DVD_BIDPEROFFER_",
    datestring,
    "010000.csv")
  )


  colnames(data_file) <- data_file[2, ]
  data_file <- data_file[-c(1:2), -c(1:4)]
  data_file <- utils::head(data_file, -1)


  data_file$SETTLEMENTDATE <- as.POSIXct(data_file$SETTLEMENTDATE,
                                         tz = "Australia/Brisbane",
                                         format = "%Y/%m/%d %H:%M:%S")


  data_file$OFFERDATE <- as.POSIXct(data_file$OFFERDATE,
                                         tz = "Australia/Brisbane",
                                         format = "%Y/%m/%d %H:%M:%S")


  data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
                                      tz = "Australia/Brisbane",
                                      format = "%Y/%m/%d %H:%M:%S")

  data_file <- data_file %>%
    dplyr::mutate(dplyr::across(.cols = !c(DUID, BIDTYPE, SETTLEMENTDATE, OFFERDATE, LASTCHANGED),
                                .fns = as.numeric))


  return(data_file)

}
