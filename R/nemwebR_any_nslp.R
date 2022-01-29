#' Retrieve Net System Load Profile data
#'
#' This function returns Net System Load Profile (NSLP) data from AEMO's NEMWeb as specified by the year argument. If the current year is queried the function will retrieve all weeks in the year.
#'
#' Net System Load Profiles are published for each distributor.
#'
#' Data is available from 2002 to 2021. This code will need updating in 2022.
#'
#' @param year integer of the form YYYY
#'
#' @return A data frame
#' @export
#'
#' @examples
#' nemwebR_any_nslp(2019)
#'
nemwebR_any_nslp <- function(year) {

  current_year <- lubridate::year(Sys.Date())

  ## Retrieve all linked NSLP files
  base_url <- "https://aemo.com.au/en/energy-systems/electricity/national-electricity-market-nem/data-nem/metering-data/load-profiles"

  ## Extract HTML structure of all linked files on the pages
  page_links <- rvest::read_html(base_url) %>%
    rvest::html_elements("li.list-item") %>%
    rvest::html_elements("a")

  ## Build dataframe of file names and links
  profiles <- data.frame(
    file_name = rvest::html_attr(page_links, "title"),
    link = rvest::html_attr(page_links, "href")
  )

  ## Add in the second page urls
  second_url <- "https://aemo.com.au/en/energy-systems/electricity/national-electricity-market-nem/data-nem/metering-data/load-profiles?2021=2"

  second_links <- rvest::read_html(second_url) %>%
    rvest::html_elements("li.list-item") %>%
    rvest::html_elements("a")

  ## Build dataframe of file names and links
  extra_profiles <- data.frame(
    file_name = rvest::html_attr(second_links, "title"),
    link = rvest::html_attr(second_links, "href")
  )


  profiles <- dplyr::bind_rows(profiles, extra_profiles)
  profiles <- unique(profiles)


  ## Rebuild full link address
  profiles$link <- stringr::str_c("https://aemo.com.au", profiles$link)

  ## Get rid of the explanation document
  profiles <- profiles[profiles$file_name != "File 1", ]


  ## Add a year column to the data
  profiles$year <- dplyr::if_else(stringr::str_detect(profiles$file_name, pattern = "Week"), "2021", profiles$file_name)


  if (year < 2002 | year > current_year) {

    stop(paste0("No data exists for that year. Please enter a year betwen 2002 and ", current_year - 1))

  } else if (year == current_year) {

    ## List of weeks in the current year
    profiles_current <- profiles[profiles$year == current_year, ]


    weekly_profiles <- list() # Create empty list to loop into

    for (i in 1:length(profiles_current$link)) {


      temp_file <- tempfile() # Create temporary file
      utils::download.file(profiles_current$link[i], destfile = temp_file, quiet = TRUE, mode = "wb")
      # Download zip to temp file - note the mode = "wb" important for Windows for certain file extensions
      xml_filename <- utils::unzip(temp_file, list = TRUE)$Name # Get the name of the contents in the zip file
      datdata <- XML::xmlInternalTreeParse(unzip(temp_file, xml_filename)) # Extract the contents of the xml file in the zip file
      unlink(temp_file) # Dump the temporary file

      parsed_data <- XML::xmlToList(datdata) # Parse xml data to an R list

      moreparsed <- stringr::str_split(
        parsed_data$Transactions$Transaction$ReportResponse$ReportResults$CSVData,
        pattern = "\n",
        simplify = TRUE) # Split the string on line breaks
      moreparsed <- t(moreparsed) # Transpose
      moreparsed <- stringr::str_split(moreparsed, pattern = ",") # Split into columns by comma delimiter

      datdataframe <- do.call(rbind, moreparsed) # Bind the list into a data frame

      datdataframe <- as.data.frame(datdataframe)

      colnames(datdataframe) <- datdataframe[1, ] # Use first row to provide column names

      datdataframe <- datdataframe[-1, ] # Dump the useless first row

      datdataframe <- head(datdataframe, -1)

      datdataframe$SettlementDate <- as.POSIXct(datdataframe$SettlementDate,
                                                timezone = "Australia/Brisbane",
                                                format = "%Y/%m/%d")

      datdataframe$CreationDT <- as.POSIXct(datdataframe$CreationDT,
                                            timezone = "Australia/Brisbane",
                                            format = "%Y/%m/%d %H:%M:%S")


      ## Convert to from wide NEM12 format to long flat format
      datdataframe <- datdataframe %>%
        tidyr::pivot_longer(
          cols = starts_with("Period"),
          names_to = "periodid",
          names_prefix = "Period",
          values_to = "load_profile"
        )

      datdataframe$periodid <- as.numeric(datdataframe$periodid)

      ## Create sequential settlementdate based on periodid
      datdataframe$SettlementDate <- datdataframe$SettlementDate + 60 * datdataframe$periodid * 30


      ## Add year and week data
      datdataframe$year <- profiles_current$year[i] # R automatically recycles elements
      #datdataframe$week <- profiles_2021$file_name[i] # R automatically recycles elements


      weekly_profiles[[i]] <- datdataframe # Populate list with data


    }


    ## Bind all the results together
    weekly_profiles_all <- do.call(bind_rows, weekly_profiles)


    ## Reverse the sort order
    weekly_profiles_all <- weekly_profiles_all[order(
      weekly_profiles_all$ProfileName,
      weekly_profiles_all$ProfileArea,
      weekly_profiles_all$SettlementDate
    ), ]


    ## Drop columns to provide compatibility with previous years
    weekly_profiles_all <- dplyr::select(weekly_profiles_all, !c(SeqNo, Locked, SettlementCase))


    ## Return the results
    return(weekly_profiles_all)


  } else {


    temp_file <- tempfile() # Create temporary file
    utils::download.file(profiles[profiles$year == year, ]$link, destfile = temp_file, quiet = TRUE, mode = "wb")
    # Download zip to temp file - note the mode = "wb" important for Windows for certain file extensions

    filenames <- utils::unzip(temp_file, list = TRUE)$Name # Get the names of the contents in the zip file

    nslp_filename <- filenames[stringr::str_detect(filenames, stringr::regex("nslp", ignore_case = TRUE))]
    cload_filename <- filenames[stringr::str_detect(filenames, stringr::regex("cload", ignore_case = TRUE))]

    nslp_data <- utils::read.csv(utils::unzip(temp_file, nslp_filename))
    cload_data <- utils::read.csv(utils::unzip(temp_file, cload_filename))


    ## Drop the SeqNo, Locked & SettlementCase columns

    nslp_data <- dplyr::select(nslp_data, !c(SeqNo, Locked, SettlementCase))
    cload_data <- dplyr::select(cload_data, !c(SeqNo, Locked, SettlementCase))

    datdataframe <- dplyr::bind_rows(nslp_data, cload_data)

    unlink(temp_file) # Dump the temporary file


    #! Of course AEMO changed the fucking date formats, didn't they.

    ## Fix the dates
    datdataframe$SettlementDate <- as.POSIXct(datdataframe$SettlementDate,
                                              timezone = "Australia/Brisbane",
                                              format = "%d/%m/%Y")


    #! R is importing the data without seconds, weirdly
    #! Could try explicitly defining the column type
    datdataframe$CreationDT <- as.POSIXct(datdataframe$CreationDT,
                                          timezone = "Australia/Brisbane",
                                          format = "%d/%m/%Y %H:%M")


    ## Convert to from wide NEM12 format to long flat format
    datdataframe <- datdataframe %>%
      tidyr::pivot_longer(
        cols = starts_with("Period"),
        names_to = "periodid",
        names_prefix = "Period",
        values_to = "load_profile"
      )

    datdataframe$periodid <- as.numeric(datdataframe$periodid)

    ## Create sequential settlementdate based on periodid
    datdataframe$SettlementDate <- datdataframe$SettlementDate + 60 * datdataframe$periodid * 30


    ## Add year and week data
    datdataframe$year <- year # R automatically recycles elements


    return(datdataframe)

  }


  ## End function

}
