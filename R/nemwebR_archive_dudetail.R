#' Retrieve archived DUDETAIL data
#'
#' This function returns one month of DUDETAIL data from AEMO's NEMWeb as specified by the datestring argument
#'
#' DUDETAIL data contains historical DUID registration details for all registered generators in the NEM.
#'
#' Archive data is available from July 2009 to approximately two weeks ago. In order to retrieve newer data you will need to use the nemwebR_current_DUDETAIL function.
#'
#'
#' @param datestring integer of the form YYYYMM
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_dudetail(202101)
#'
nemwebR_archive_dudetail <- function(datestring) {

  temp <- tempfile()
  utils::download.file(url = stringr::str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    stringr::str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    stringr::str_sub(datestring, start = 1, end = 4),
    "_",
    stringr::str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_DUDETAIL_",
    datestring,
    "010000.zip"),
    destfile = temp, mode = "wb", quiet = TRUE)


  data_file <- utils::read.csv(utils::unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(stringr::str_c(
    "PUBLIC_DVD_DUDETAIL_",
    datestring,
    "010000.csv")
  )


  colnames(data_file) <- data_file[2, ]
  data_file <- data_file[-c(1:2), -c(1:4)]
  data_file <- utils::head(data_file, -1)


  data_file$EFFECTIVEDATE <- as.POSIXct(data_file$EFFECTIVEDATE,
                                         tz = "Australia/Brisbane",
                                         format = "%Y/%m/%d %H:%M:%S")

  data_file$AUTHORISEDDATE <- as.POSIXct(data_file$AUTHORISEDDATE,
                                        tz = "Australia/Brisbane",
                                        format = "%Y/%m/%d %H:%M:%S")

  data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
                                      tz = "Australia/Brisbane",
                                      format = "%Y/%m/%d %H:%M:%S")



  ## Check if all columns exist, add dummy columns into the data
  missing_columns <- setdiff(
    c("MAXRATEOFCHANGEUP", "MAXRATEOFCHANGEDOWN"),
    colnames(data_file)
  )

  if(length(missing_columns != 0)) {
    data_file[ , missing_columns] <- NA
  }


  data_file <- data_file %>%
    dplyr::mutate(dplyr::across(
      .cols = c(VERSIONNO, VOLTLEVEL, REGISTEREDCAPACITY, MAXCAPACITY, MAXRATEOFCHANGEUP, MAXRATEOFCHANGEDOWN),
      .fns = as.numeric
      )
    )

  # Filter only the most recent registration details (should be 1:1 DUID to row relationship)
  data_file <- data_file %>%
    dplyr::group_by(DUID) %>%
    dplyr::slice(which.max(AUTHORISEDDATE)) %>%
    dplyr::ungroup()


  return(data_file)

}
