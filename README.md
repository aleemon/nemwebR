
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
For clarity, only public datasets (or private; public next day) are
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

This is a basic example which shows you how to solve a common problem:

``` r
library(nemwebR)
library(purrr)
## fetch pricing data for 2020

input <- seq(20200101, 20201201, by = 100)

prices_2020 <- map_dfr(input, nemwebR_archive_tradingprice)
```

## Development

nemwebR is under active development and features may be added or
removed. There are number of obvious areas for improvment, but the core
functions are sufficient for most applications.
