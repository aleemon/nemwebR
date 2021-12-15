
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
run ad hoc analyses on NEM data, primarily on historical (&gt; 2 months
old) datasets.

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
-   Data types have all been strictly enforced

Depending on the volume of data and update frequency in a given
dataset,archive (historical) data usually starts from \~ 2 weeks prior
and stretches back to July 2009. Current (recent) data usually stretches
back \~ 1 year. The archive functions are typically faster and more
efficient than the current functions, so try to use them where possible.

For high volume versioned datasets (i.e. the predispatch and bidding
data) the current data contains all versions whereas the archive data
only keeps the latest value (i.e. the current data retrieves BIDDAYOFFER
whereas the archive retrieves BIDDAYOFFER\_D). Unfortunately this
somewhat limits the value of analysis from these datasets and is just
one of many quirks of the data available on NEMWeb.

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

*Note that these data are no longer updated as of 1 October 2021*

-   TRADINGINTERCONNECT – Interconnector flows and limits
-   TRADINGLOAD – Scheduled and semi-scheduled generator outputs
-   TRADINGPRICE – Regional prices
-   TRADINGREGIONSUM – Regional demand and non-scheduled generation

## Available Datasets - Current

-   DISPATCHPRICE (incomplete)

## Non-NEMWeb data

-   Net System Load Profiles – Annual NSLP data for 2002 onwards

## Installation

Install the current version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("aleemon/nemwebR")
```

## Example

A (very) basic example of fetching pricing data:

``` r
library(nemwebR)
library(purrr)

## fetch 30-minute pricing data for the first 3 months of 2020
input <- seq(20200101, 20200301, by = 100)

prices_q1_2020 <- map_dfr(input, nemwebR_archive_tradingprice)

head(prices_q1_2020)
#>        SETTLEMENTDATE RUNNO REGIONID PERIODID   RRP EEP INVALIDFLAG
#> 1 2020-01-01 18:30:00     1     NSW1       37 63.57   0           0
#> 2 2020-01-01 18:30:00     1     VIC1       37 64.14   0           0
#> 3 2020-01-01 18:30:00     1      SA1       37 64.59   0           0
#> 4 2020-01-01 18:30:00     1     QLD1       37 70.88   0           0
#> 5 2020-01-01 18:30:00     1     TAS1       37 66.56   0           0
#> 6 2020-01-01 20:00:00     1     NSW1       40 67.22   0           0
#>           LASTCHANGED   ROP RAISE6SECRRP RAISE6SECROP RAISE60SECRRP
#> 1 2020-01-01 18:25:03 63.57        20.34        20.34         13.07
#> 2 2020-01-01 18:25:03 64.14        20.34        20.34         13.07
#> 3 2020-01-01 18:25:03 64.59        20.34        20.34         13.07
#> 4 2020-01-01 18:25:03 70.88        20.34        20.34         13.07
#> 5 2020-01-01 18:25:03 66.56        53.45        53.45         13.00
#> 6 2020-01-01 19:55:03 67.22        18.65        18.65          5.87
#>   RAISE60SECROP RAISE5MINRRP RAISE5MINROP RAISEREGRRP RAISEREGROP LOWER6SECRRP
#> 1         13.07         0.89         0.89       68.30       68.30         0.04
#> 2         13.07         0.89         0.89       68.30       68.30         0.04
#> 3         13.07         0.89         0.89       68.30       68.30         0.04
#> 4         13.07         0.89         0.89       68.30       68.30         0.04
#> 5         13.00         0.89         0.89        0.89        0.89         0.04
#> 6          5.87         0.70         0.70       79.47       79.47         0.04
#>   LOWER6SECROP LOWER60SECRRP LOWER60SECROP LOWER5MINRRP LOWER5MINROP
#> 1         0.04          0.19          0.19         0.16         0.16
#> 2         0.04          0.19          0.19         0.16         0.16
#> 3         0.04          0.19          0.19         0.16         0.16
#> 4         0.04          0.19          0.19         0.16         0.16
#> 5         0.04          0.19          0.19         0.16         0.16
#> 6         0.04          0.19          0.19         0.16         0.16
#>   LOWERREGRRP LOWERREGROP PRICE_STATUS
#> 1       19.72       19.72         FIRM
#> 2       19.72       19.72         FIRM
#> 3       19.72       19.72         FIRM
#> 4       19.72       19.72         FIRM
#> 5       19.72       19.72         FIRM
#> 6       20.33       20.33         FIRM
```

## Development

nemwebR is under active development and features may be added or
removed. There are number of obvious areas for improvement, but the core
functions are sufficient for many analysis applications.

Future improvements:

-   Speed improvements – the functions are currently built on the base
    `read.csv()` function which is significantly slower than either
    `dplyr::read_csv()` or `data.table::fread()`. Unfortunately these
    functions don’t play nice with the awkward formatting of AEMO csv
    files.

-   Efficiently pulling in report data from across the archive and
    current datasets

-   Change the datestring entry over to a more logical YYYYMM format

-   Improve the error handling and error messaging

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
