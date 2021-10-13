#' Retrieve archived DISPATCHPRICE data
#'
#' This function returns one month of DISPATCHPRICE data from AEMO's NEMWeb as specified by the datestring argument
#'
#' DISPATCHPRICE data contains historical 5-minute generation quantities for all scheduled and non-scheduled generators in the NEM.
#'
#' Archive data is available from July 2009 to approximately one month ago. In order to retrieve newer data you will need to use the nemwebR_current_DISPATCHPRICE function.
#'
#'
#' @param datestring integer of the form YYYYMMDD
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_archive_dispatchprice(20210101)
#'
nemwebR_archive_dispatchprice <- function(datestring) {

  temp <- tempfile()
  utils::download.file(url = stringr::str_c(
    "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
    stringr::str_sub(datestring, start = 1, end = 4),
    "/MMSDM_",
    stringr::str_sub(datestring, start = 1, end = 4),
    "_",
    stringr::str_sub(datestring, start = 5, end = 6),
    "/MMSDM_Historical_Data_SQLLoader/DATA/",
    "PUBLIC_DVD_DISPATCHPRICE_",
    datestring,
    "0000.zip"),
    destfile = temp, mode = "wb")


  data_file <- utils::read.csv(utils::unzip(temp), header = FALSE)


  ## Dump the files from the hard drive
  unlink(temp)

  unlink(stringr::str_c(
    "PUBLIC_DVD_DISPATCHPRICE_",
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


  #! There was a change in the file specification from November 2009 onwards
    # The very old files only have 36 columns
    # All newer files have additional 18 pre-AP and cumulative price columns [37:54]

  ##  Correct the column data types based on explicitly named date or character type columns
  data_file <- data_file %>%
    dplyr::mutate(dplyr::across(.cols = !c(SETTLEMENTDATE, REGIONID, LASTCHANGED, PRICE_STATUS),
                                .fns = as.numeric)) # check this works
  # Old implementation:
  #data_file <- data_file %>% dplyr::mutate(dplyr::across(.cols = c(2, 4:10, 12:35, 37:54), .fns = as.numeric))


  ## Add in missing columns to preserve joining with newer datasets (where were they stored previously?)
  if(ncol(data_file) == 36) {

    missing_columns <- data.frame(
      PRE_AP_ENERGY_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_RAISE6_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_RAISE60_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_RAISE5MIN_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_RAISEREG_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_LOWER6_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_LOWER60_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_LOWER5MIN_PRICE = as.numeric(rep(NA, nrow(data_file))),
      PRE_AP_LOWERREG_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_ENERGY_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_RAISE6_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_RAISE60_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_RAISE5MIN_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_RAISEREG_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_LOWER6_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_LOWER60_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_LOWER5MIN_PRICE = as.numeric(rep(NA, nrow(data_file))),
      CUMUL_PRE_AP_LOWERREG_PRICE = as.numeric(rep(NA, nrow(data_file)))
    )

    data_file <- dplyr::bind_cols(data_file, missing_columns)

  }


  ## Correct the intervention naming (could introduce unwanted grouping?)
  data_file <- data_file %>% dplyr::group_by(REGIONID, SETTLEMENTDATE) %>%
    dplyr::slice(which.min(INTERVENTION)) %>% dplyr::ungroup()


  return(data_file)

}
