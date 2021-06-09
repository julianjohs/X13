# X13
X13-ARIMA-SEATS seasonal decomposition

This package wraps the R package [x12](https://github.com/statistikat/x12) via [RCall](https://github.com/JuliaInterop/RCall.jl), which provides the U.S. Census Bureau's
X13-ARIMA-SEATS seasonal adjustment method. 

Note that the x12 R package doesn't seem to be actively developed. There exist some native Julia solutions for similar problems in other packages: The [TSAnalysis](https://github.com/fipelle/TSAnalysis.jl) package provides ARIMA models as well as Kalman filter-based methods for trend-cycle decomposition. [Forecast.jl](https://github.com/viraltux/Forecast.jl) provides seasonal decomposition based on LOESS (Locally Estimated Scatterplot Smoothing).


## Installation

To install this package, please follow the instructions on [how to install RCall](http://juliainterop.github.io/RCall.jl/stable/installation/).
After properly installing RCall, you can add this package via pkg:

```julia
Pkg.add("https://github.com/julianjohs/X13")
```


It might be necessary to set the environmental variable before the using command:

```julia
julia> ENV["R_HOME"] = "....directory of R home...."

julia> using X13
```

Note that this package has not been tested on Mac OS X or Linux. To use the package on these platforms, refer to the Readme of the x12 R package.

## Example

```julia
julia> using X13

julia> ta = sample_ts('q')
80×1 TimeArray{Float64,1,Dates.Date,Array{Float64,1}} 1999-01-01 to 2018-10-01
│            │ A      │
├────────────┼────────┤
│ 1999-01-01 │ 0.1381 │
│ 1999-04-01 │ 0.7961 │
│ 1999-07-01 │ 0.9005 │
│ 1999-10-01 │ 0.4219 │
│ 2000-01-01 │ 0.6575 │
   ⋮
│ 2018-01-01 │ 0.4006 │
│ 2018-04-01 │ 0.3303 │
│ 2018-07-01 │ 0.2201 │
│ 2018-10-01 │ 0.4007 │

julia> ta_x13 = x13(ta)

julia> seas = season_adjust(ta)
80×1 TimeArray{Float64,1,Dates.Date,Array{Float64,1}} 1999-01-01 to 2018-10-01
│            │ A      │
├────────────┼────────┤
│ 1999-01-01 │ 0.0266 │
│ 1999-04-01 │ 0.6617 │
│ 1999-07-01 │ 0.8937 │
│ 1999-10-01 │ 0.6759 │
│ 2000-01-01 │ 0.5432 │
   ⋮
│ 2018-01-01 │ 0.5736 │
│ 2018-04-01 │ 0.2413 │
│ 2018-07-01 │ 0.2715 │
│ 2018-10-01 │ 0.2629 │
``` 
The output of x13 has type X13Output and is modelled after the R class X12Output provided by the x12 package. season_adjust() provides quick access to the seasonally adjusted time series. 

## Features

As of now, this package is only able to provide basic X13 adjustment as outlined in the x12 R package documentation, for monthly and quarterly time series. More
features and specifications might be added in the future.

This package also provides a way to import regular TimeArrays (as in the [TimeSeries](https://github.com/JuliaStats/TimeSeries.jl) package) into R. 
