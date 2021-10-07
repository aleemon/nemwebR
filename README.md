
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nemwebR

<!-- badges: start -->
<!-- badges: end -->

The goal of nemwebR is to enable easy downloading of datasets from the
[AEMO NEM Web
site](https://www.aemo.com.au/energy-systems/electricity/national-electricity-market-nem/data-nem/market-data-nemweb).

nemwebR has a series of functions for fetching common datasets such as
market prices, generator outputs or bids.

The naming and design of these functions is intended to mirror the
naming and conventions of the [MMS Data Model
Report](http://nemweb.com.au/Reports/Current/MMSDataModelReport/Electricity/MMS%20Data%20Model%20Report_files/MMS_2.htm).
For clarity, only *public* datasets (or *private; public next day*) are
available.

There are a few key differences relative to the raw AEMO data: - AEMO
csv headers and footers are removed so that the data is ready to use -
Empty and deprecated columns are stripped out to keep the data cleaner -
When dealing with dispatch datasets intervention heirachies have already
been implemented correctly - All dates and times are formatted in POSIX
+10 (Australia/Brisbane)

## Installation

Install the current version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("aleemon/nemwebR")
```

## Example

A basic example to fetch a year of pricing data:

``` r
library(nemwebR)
library(purrr)

## fetch pricing data for 2020
input <- seq(20200101, 20201201, by = 100)

prices_2020 <- map_dfr(input, nemwebR_archive_tradingprice)

head(prices_2020)
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
functions are sufficient for most applications.

Future improvements:

-   Speed improvements – the functions are currently built on the base
    `read.csv()` function, `dplyr::read_csv()` isn’t usable because of
    the AEMO header structure. A read function from the Data Table
    package will likely help improve speed

-   Formatting challenge — Current reports are released based on AEMO
    trading days (4:30 - 4:00 AM) whereas archive datasets are stored
    based on settlement (i.e. starting and ending at midnight)
