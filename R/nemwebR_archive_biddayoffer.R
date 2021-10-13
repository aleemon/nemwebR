
nemwebR_archive_biddayoffer
# get_biddayoffer_archive <- function(datestring) {
#
#   temp <- tempfile()
#   download.file(url = str_c(
#     "https://nemweb.com.au/Data_Archive/Wholesale_Electricity/MMSDM/",
#     str_sub(datestring, start = 1, end = 4),
#     "/MMSDM_",
#     str_sub(datestring, start = 1, end = 4),
#     "_",
#     str_sub(datestring, start = 5, end = 6),
#     "/MMSDM_Historical_Data_SQLLoader/DATA/",
#     "PUBLIC_DVD_BIDDAYOFFER_",
#     datestring,
#     "0000.zip"),
#     destfile = temp, mode = "wb")
#
#
#   data_file <- read.csv(unzip(temp), header = FALSE)
#
#
#   ## Dump the files from the hard drive
#   unlink(temp)
#
#   unlink(str_c(
#     "PUBLIC_DVD_BIDDAYOFFER_",
#     datestring,
#     "0000.csv")
#   )
#
#
#   colnames(data_file) <- data_file[2, ]
#   data_file <- data_file[-c(1:2), -c(1:4)]
#   data_file <- head(data_file, -1)
#
#
#   ## Don't convert datetime data to posix class, for SQLite compatibility
#   # data_file$SETTLEMENTDATE <- as.POSIXct(data_file$SETTLEMENTDATE,
#   #                                        tz = "Australia/Brisbane",
#   #                                        format = "%Y/%m/%d %H:%M:%S")
#   #
#   # data_file$LASTCHANGED <- as.POSIXct(data_file$LASTCHANGED,
#   #                                     tz = "Australia/Brisbane",
#   #                                     format = "%Y/%m/%d %H:%M:%S")
#
#   data_file <- data_file %>% mutate(across(.cols = c(2, 4:15, 17:20), .fns = as.numeric))
#
#
#   return(data_file)
#
# }
