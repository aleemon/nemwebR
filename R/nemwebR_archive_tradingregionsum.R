#' Retrieve archived TRADINGREGIONSUM data
#'
#' This function returns one month of TRADINGREGIONSUM data from AEMO's NEMWeb as specified by the datestring argument
#'
#' TRADINGREGIONSUM data contains historical 30-minute demand and non-scheduled generation quantities for all NEM regions.
#'
#' Archive data is available from July 2009 to 30 September 2021 when 5MS was implemented. In order to retrieve newer data you will need to use the nemwebR_current_DISPATCHREGIONSUM function.
#'
#'
#' @param datestring integer of the form YYYYMMDD
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_tradingregionsum(20210101)
#'
nemwebR_archive_tradingregionsum <- function(datestring) {

  temp <- tempfile()
  utils::download.file(url = stringr::str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    stringr::str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    stringr::str_sub(datestring, start = 1, end = 4),
    "_",
    stringr::str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_TRADINGREGIONSUM_",
    datestring,
    "0000.zip"),
    destfile = temp, mode = "wb")


  data_file <- utils::read.csv(utils::unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(stringr::str_c(
    "PUBLIC_DVD_TRADINGREGIONSUM_",
    datestring,
    "0000.csv")
  )


  colnames(data_file) <- data_file[2, ]
  data_file <- data_file[-c(1:2), -c(1:4)]
  data_file <- utils::head(data_file, -1)


  data_file$SETTLEMENTDATE <- as.POSIXct(data_file$SETTLEMENTDATE,
                                         tz = "Australia/Brisbane",
                                         format = "%Y/%m/%d %H:%M:%S")

  data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
                                      tz = "Australia/Brisbane",
                                      format = "%Y/%m/%d %H:%M:%S")

  ## Drop the redundant columns

  data_file <-  data_file %>% dplyr::select(
    !c(LOWER5MINDISPATCH, LOWER5MINIMPORT, LOWER5MINLOCALPRICE, LOWER5MINLOCALREQ, LOWER5MINPRICE, LOWER5MINREQ, LOWER5MINSUPPLYPRICE,
       LOWER60SECDISPATCH, LOWER60SECIMPORT, LOWER60SECLOCALPRICE, LOWER60SECLOCALREQ, LOWER60SECPRICE, LOWER60SECREQ, LOWER60SECSUPPLYPRICE,
       LOWER6SECDISPATCH, LOWER6SECIMPORT, LOWER6SECLOCALPRICE, LOWER6SECLOCALREQ, LOWER6SECPRICE, LOWER6SECREQ, LOWER6SECSUPPLYPRICE,
       RAISE5MINDISPATCH, RAISE5MINIMPORT, RAISE5MINLOCALPRICE, RAISE5MINLOCALREQ, RAISE5MINPRICE, RAISE5MINREQ, RAISE5MINSUPPLYPRICE,
       RAISE60SECDISPATCH, RAISE60SECIMPORT, RAISE60SECLOCALPRICE, RAISE60SECLOCALREQ, RAISE60SECPRICE, RAISE60SECREQ, RAISE60SECSUPPLYPRICE,
       RAISE6SECDISPATCH, RAISE6SECIMPORT, RAISE6SECLOCALPRICE, RAISE6SECLOCALREQ, RAISE6SECPRICE, RAISE6SECREQ, RAISE6SECSUPPLYPRICE,
       LOWERREGIMPORT, LOWERREGLOCALREQ, LOWERREGREQ,
       RAISEREGIMPORT, RAISEREGLOCALREQ, RAISEREGREQ,
       RAISE5MINLOCALVIOLATION, RAISEREGLOCALVIOLATION, RAISE60SECLOCALVIOLATION, RAISE6SECLOCALVIOLATION,
       LOWER5MINLOCALVIOLATION, LOWERREGLOCALVIOLATION, LOWER60SECLOCALVIOLATION, LOWER6SECLOCALVIOLATION,
       RAISE5MINVIOLATION, RAISEREGVIOLATION, RAISE60SECVIOLATION, RAISE6SECVIOLATION,
       LOWER5MINVIOLATION, LOWERREGVIOLATION, LOWER60SECVIOLATION, LOWER6SECVIOLATION
    ))


  data_file <- dplyr::mutate(data_file, dplyr::across(.cols = c(2, 4:18, 20:26), .fns = as.numeric))


  return(data_file)

}
