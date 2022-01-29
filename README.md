
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nemwebR

<!-- badges: start -->
<!-- badges: end -->

The goal of `nemwebR` is to enable easy downloading of datasets from the
[AEMO NEM Web
site](https://www.aemo.com.au/energy-systems/electricity/national-electricity-market-nem/data-nem/market-data-nemweb).
`nemwebR` has a series of functions for fetching common datasets such as
market prices, generator outputs or bids.

`nemwebR` is designed specifically for those looking to access market
data but without access to the MMS Data Model typically available to
registered market participants. The likely user is someone looking to
run ad hoc analyses on NEM data, primarily on historical datasets (&gt;
2 weeks old).

The naming and design of these functions is intended to mirror the
naming and conventions of the [MMS Data Model
Report](http://nemweb.com.au/Reports/Current/MMSDataModelReport/Electricity/MMS%20Data%20Model%20Report_files/MMS_2.htm).
For clarity, only *public* datasets (or *private; public next day*) are
available.

## Notes

“Why does this package exist if I can just download the csv files from
NEMWeb?” Great question. Here’s why:

-   AEMO csv headers and footers are removed so that the data is ready
    to use in a clean tabular format
-   csv files containing multiple datasets are split out into their
    consituent datasets
-   Empty and deprecated columns are stripped out to keep the final data
    cleaner
-   When dealing with dispatch datasets intervention hierarchies have
    been implemented correctly
-   All dates and times are formatted in POSIX +10 timezone
    (Australia/Brisbane)
-   Data types have all been strictly enforced (i.e. dates as POSIX,
    numeric where they should be)

Depending on the volume of data and update frequency in a given
dataset,archive (historical) data usually starts from \~ 2 weeks prior
and stretches back to July 2009. Current (recent) data usually stretches
back \~ 1 year. The archive functions are typically faster and more
efficient than the current functions, so try to use them where possible.

## Five Minute Settlement

As of 1 October 2021 the NEM is dispatched and settled in 5 minute
intervals (previously the NEM was dispatched in 5 minute intervals and
settled on 30 minute intervals). The old 30 minute interval *trading*
datasets are no longer valid for new data, but exist for historical
purposes.

## Available Datasets - Archive

### Dispatch Data

-   DISPATCH\_FCAS\_REQ – Regional FCAS requirements
-   DISPATCHLOAD – Scheduled and semi-scheduled generator outputs
-   DISPATCHPRICE – Regional prices
-   DISPATCHREGIONSUM – Regional demand and non-scheduled generation

### Generator Registration data

-   DUDETAILSUMMARY – Summary of registration details for all registered
    generators
-   DUDETAIL – Registration details for all registered generators
-   GENUNITS – Summary of individual unit registration details,
    including fuel type and CO<sub>2</sub> emission information

### Bid Data

-   BIDDAYOFFER – Bid price band data for energy and FCAS markets
    submitted by generators
-   BIDPEROFFER – Bid generation volumes for energy and FCAS markets
    submitted by generators
-   BIDDUIDDETAILS – Enablement levels and FCAS trapezium ffor each
    generator

### Trading Data (Historical 30-minute data)

*Note that these data are no longer updated as of 1 October 2021 due to
5MS*

-   TRADINGINTERCONNECT – Interconnector flows and limits
-   TRADINGLOAD – Scheduled and semi-scheduled generator outputs
-   TRADINGPRICE – Regional prices
-   TRADINGREGIONSUM – Regional demand and non-scheduled generation

## Available Datasets - Current

-   DISPATCHPRICE (incomplete, messy)

## Non-NEMWeb data

-   Net System Load Profiles – Annual NSLP data for 2002 onwards

## Installation

Currently only on GitHub, if the package becomes stable enough it might
find its way to CRAN.

Install the current version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("aleemon/nemwebR")
```

## Example

A (very) basic example of fetching pricing data across for a given
period:

``` r
library(nemwebR)
library(tidyverse) # To grab purrr, stringr and the pipe


## Fetch 30-minute pricing for late 2019, early 2020
input <- seq.Date(as.Date("2019-11-01"), as.Date("2020-02-01"), by = "month") %>% str_remove_all("-") %>% str_sub(1, 6)

example_prices <- map_dfr(input, nemwebR_archive_tradingprice)

head(example_prices)
#>        SETTLEMENTDATE RUNNO REGIONID PERIODID   RRP EEP INVALIDFLAG
#> 1 2019-11-08 01:00:00     1     QLD1        2 48.59   0           0
#> 2 2019-11-08 01:00:00     1     TAS1        2 44.15   0           0
#> 3 2019-11-08 01:30:00     1     NSW1        3 48.04   0           0
#> 4 2019-11-08 01:30:00     1     VIC1        3 44.58   0           0
#> 5 2019-11-08 01:30:00     1      SA1        3 44.34   0           0
#> 6 2019-11-08 01:30:00     1     QLD1        3 48.11   0           0
#>           LASTCHANGED   ROP RAISE6SECRRP RAISE6SECROP RAISE60SECRRP
#> 1 2019-11-08 00:55:03 48.59         4.87         4.87          2.80
#> 2 2019-11-08 00:55:03 44.15         4.87         4.87          2.80
#> 3 2019-11-08 01:25:04 48.04         4.73         4.73          2.79
#> 4 2019-11-08 01:25:04 44.58         4.73         4.73          2.79
#> 5 2019-11-08 01:25:04 44.34         4.73         4.73          2.79
#> 6 2019-11-08 01:25:04 48.11         4.73         4.73          2.79
#>   RAISE60SECROP RAISE5MINRRP RAISE5MINROP RAISEREGRRP RAISEREGROP LOWER6SECRRP
#> 1          2.80          0.7          0.7       18.33       18.33         0.05
#> 2          2.80          0.7          0.7       18.33       18.33         0.05
#> 3          2.79          0.7          0.7       14.92       14.92         0.05
#> 4          2.79          0.7          0.7       14.92       14.92         0.05
#> 5          2.79          0.7          0.7       14.92       14.92         0.05
#> 6          2.79          0.7          0.7       14.92       14.92         0.05
#>   LOWER6SECROP LOWER60SECRRP LOWER60SECROP LOWER5MINRRP LOWER5MINROP
#> 1         0.05          0.19          0.19         0.19         0.19
#> 2         0.05          0.19          0.19         0.17         0.17
#> 3         0.05          0.19          0.19         0.19         0.19
#> 4         0.05          0.19          0.19         0.19         0.19
#> 5         0.05          0.19          0.19         0.19         0.19
#> 6         0.05          0.19          0.19         0.19         0.19
#>   LOWERREGRRP LOWERREGROP PRICE_STATUS
#> 1       16.52       16.52         FIRM
#> 2       16.40       16.40         FIRM
#> 3       16.41       16.41         FIRM
#> 4       16.41       16.41         FIRM
#> 5       16.41       16.41         FIRM
#> 6       16.41       16.41         FIRM
```

## Development

nemwebR is under active development and features may be added or
removed. There are number of obvious areas for improvement, but the core
functions are sufficient for many analysis applications.

### Future Datasets

-   DISPATCHCONSTRAINT
-   DISPATCHINTERCONNECTORRES
-   DISPATCHCASE\_OCD
-   CONSTRAINTRELAXATION\_OCD
-   GENCONDATA
-   GENCONSET
-   GENCONSETINVOKE
-   GENERICCONSTRAINTRHS
-   GENERICEQUATIONDESC
-   GENERICEQUATIONRHS
-   INTERCONNECTOR
-   INTERCONNECTORCONSTRAINT
-   LOSSFACTORMODEL
-   LOSSMODEL
-   MARKET\_PRICE\_THRESHOLDS
-   MARKETFEE
-   MARKETFEEDATA
-   MARKETNOTICEDATA
-   MARKETNOTICETYPE
-   MTPASA datasates
-   P5MIN datasets
-   PDPASA datasets
-   PREDISPATCH datasets
-   RESIDUE datasets
-   ROOFTOP\_PV\_ACTUAL
-   ROOFTOP\_PV\_FORECAST
-   STPASA datasets
-   TRANSMISSIONLOSSFACTOR
