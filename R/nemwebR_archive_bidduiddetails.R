#' Retrieve archived DISPATCH_FCAS_REQ data
#'
#' This function returns one month of DISPATCH_FCAS_REQ data from AEMO's NEMWeb as specified by the datestring argument
#'
#' DISPATCH_FCAS_REQ data contains historical 5-minute generation quantities for all scheduled and non-scheduled generators in the NEM.
#'
#' Archive data is available from July 2009 to approximately one month ago. In order to retrieve newer data you will need to use the nemwebR_current_DISPATCH_FCAS_REQ function.
#'
#'
#' @param datestring integer of the form YYYYMMDD
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_dispatch_fcas_req(20210101)
#'
nemwebR_archive_bidduiddetails <- function(datestring) {

  temp <- tempfile()
  download.file(url = str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    str_sub(datestring, start = 1, end = 4),
    "_",
    str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_BIDDUIDDETAILS_",
    datestring,
    "0000.zip"),
    destfile = temp, mode = "wb")


  data_file <- read.csv(unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(str_c(
    "PUBLIC_DVD_BIDDUIDDETAILS_",
    datestring,
    "0000.csv")
  )


  colnames(data_file) <- data_file[2, ] # Name columns
  data_file <- data_file[-c(1:2), -c(1:4)] # Remove extraneous information
  data_file <- head(data_file, -1) # Remove the last row of extraneous information



  data_file$EFFECTIVEDATE <- as.POSIXct(data_file$EFFECTIVEDATE,
                                        tz = "Australia/Brisbane",
                                        format = "%Y/%m/%d %H:%M:%S")

  data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
                                      tz = "Australia/Brisbane",
                                      format = "%Y/%m/%d %H:%M:%S")


  data_file <- data_file %>% mutate(across(.cols = c(3, 5:9), .fns = as.numeric))


  return(data_file)

}
