# X13
X13-ARIMA-SEATS seasonal decomposition

This package wraps the R package [x12](https://github.com/statistikat/x12) via [RCall](https://github.com/JuliaInterop/RCall.jl), which provides the U.S. Census Bureau's
X13-ARIMA-SEATS seasonal adjustment method. 

## Installation

To install this package, please follow the instructions on [how to install RCall](http://juliainterop.github.io/RCall.jl/stable/installation/).
After properly installing RCall, you can add this package via pkg:

```julia
Pkg.add("https://github.com/julianjohs/X13")
```


It might be necessary to set the environmental variable before the using command:

```julia
ENV["R_HOME"] = "....directory of R home...."
using X13
```

Note that this package has not been tested on Mac OS X or Linux. To use the package on these platforms, refer to the Readme of the x12 R package.

## Features

As of now, this package is only able to provide basic X13 adjustment as outlined in the x12 R package documentation, for monthly and quarterly time series. More
features and specifications might be added in the future.

This package also provides a way to import regular TimeArrays (as in the [TimeSeries](https://github.com/JuliaStats/TimeSeries.jl) package) into R. 
