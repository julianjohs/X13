# ENV["R_HOME"] = "C:/Program Files/R/R-4.0.0"

module X13

greet() = print("Hello World!")

# Dependencies, import export
using Dates
using RCall
using TimeSeries
import TimeSeries.TimeArray
export sample_ts
export TimeArray
export x13
export season_adjust
export X13Output, Spectrum, Fbcast

# define Types
struct Spectrum
    frequency
    spectrum
end #struct
struct Fbcast
    estimate
    lowerci
    upperci
end #struct
struct X13Output
    a1::TimeArray
    d10::TimeArray
    d11::TimeArray
    d12::TimeArray
    d13::TimeArray
    d16::TimeArray
    c17::TimeArray
    d9::TimeArray
    e2::TimeArray
    d8::TimeArray
    b1::TimeArray
    td
    otl
    sp0::Spectrum
    sp1::Spectrum
    sp2::Spectrum
    spr::Spectrum
    forecast::Fbcast
    backcast::Fbcast
    dg::AbstractDict
    file
    tblnames::Array{AbstractString, 1}
    Rtblnames::Array{AbstractString, 1}
end #struct

# R dependencies - install if necessary
reval("if (!require(x12)) {install.packages('x12')}")
reval("library(x12)")
@warn "Ignore the warning above; the developer team of the x12 R library does not provide any support for this Julia package!"
reval("paths = .libPaths()")# rightpath
@rget paths
# get correct X13 path - throw error if not found
found = false
for p in paths
    binpath = string(p, "/x13binary/bin/x13ashtml.exe")
    if isfile(binpath)
        print(string("Found X13 binaries at ", binpath))
        global found = true
        global x13path = binpath
        break
    end #if
end #for
if found == false
    error("could not locate X13 binaries; please check!")
end #if

"""
Generate sample TimeArray. Allowed arguments are years (Integer)
and frequency (one of 'm', 'q', 'a'). The base year is 1999. Values are random.
"""
function sample_ts(years::Integer=20, frequency::AbstractChar='q')
    if lowercase(frequency)=='q'
        dates = Date(1999, 1, 1):Month(3):Date(1999+years-1, 10, 1)
    elseif lowercase(frequency)=='m'
        dates = Date(1999, 1, 1):Month(1):Date(1999+years-1, 12, 1)
    elseif lowercase(frequency)=='a'
        dates = Date(1999, 1, 1):Year(1):Date(1999+years-1, 1, 1)
    else
        @warn "invalid frequency input; defaulting to quarterly data"
        return sample_ts(years, frequency='q')
    end # if
    ta = TimeArray(dates, rand(length(dates)))
    return ta
end #function
sample_ts(frequency::AbstractChar) = sample_ts(20, frequency)

"""
Imports quarterly Julia TimeArray into R as ts.
"""
function as_r_ts_quart(timearray::TimeArray, name::AbstractString)
    start = timestamp(timearray)[1]
    startyr = year(start)
    startqtr = quarterofyear(start)
    vals = values(timearray)
    @rput vals
    reval("$name = ts(data=vals, start=c($startyr, $startqtr), frequency=4)")
    return name
end #function

"""
Imports monthly Julia TimeArray into R as ts.
"""
function as_r_ts_month(timearray::TimeArray, name::AbstractString)
    start = timestamp(timearray)[1]
    startyr = year(start)
    startmon = month(start)
    vals = values(timearray)
    @rput vals
    reval("$name = ts(data=vals, start=c($startyr, $startmon), frequency=12)")
    return name
end #function

"""
Extends TimeSeries.TimeArray by a method to generate a TimeArray with arbitrary years,
but set frequency.
"""
function TimeArray(array::AbstractArray, frequency::AbstractChar='q')
    len = length(array)
    if lowercase(frequency)=='q'
        dates = Date(1):Month(3):(Date(1) + Month(3 * (len - 1)))
    elseif lowercase(frequency)=='a'
        dates = Date(1):Year(1):(Date(1) + Year(len - 1))
    elseif lowercase(frequency)=='m'
        dates = Date(1):Month(1):(Date(1) + Month(len - 1))
    else
        @warn "invalid frequency input; defaulting to quarterly data"
        return TimeArray(array, frequency='q')
    end
    return TimeArray(dates, array)
end #function

"""
Determines frequency of sequence of Dates/TimeArray by comparing the first two values.
This will most likely fail or yield wrong results if the time series is too irregular.
"""
function determine_freq(times::AbstractArray{Date})
    timediff = times[2] - times[1]
    if Day(85) <= timediff <= Day(95)
        return 'q'
    elseif Day(25) <= timediff <= Day(35)
        return 'm'
    elseif Day(355) <= timediff <= Day(375)
        return 'a'
    else
        @error "frequency of time series could not be determined; difference between first two observations is $timediff \n note that this function only supports monthly, quarterly and yearly data"
    end #if
end #function
determine_freq(ta::TimeArray) = determine_freq(timestamp(ta))

"""
Provide one more year of Dates. Available for quarterly and monthly series
(not needed for annual since there is no sensible annual X12).
"""
function extend_timestamp(times::AbstractArray{Date}, frequency::AbstractChar='q')
    if lowercase(frequency)=='q'
        return times[1]:Month(3):(times[lastindex(times)] + Year(1))
    elseif lowercase(frequency)=='m'
        return times[1]:Month(1):(times[lastindex(times)] + Year(1))
    else
        @error "invalid frequency input"
    end #if
end
extend_timestamp(timearray::TimeArray) = extend_timestamp(timestamp(timearray), determine_freq(timearray))
extend_timestamp(timearray::TimeArray, frequency::AbstractChar) = extend_timestamp(timestamp(timearray), frequency)

"""
Perform X12 estimation. The function will take a frequency identifer, or,
in absence of an identifier, calculate the frequency itself (via determine_freq).
"""
function x13(ta::TimeArray, frequency::AbstractChar)
    reval("x12::x12path('$x13path')") # set path to binaries (once more)
    if lowercase(frequency)=='q'
        as_r_ts_quart(ta, "r_timeseries") # port TimeArray to R
    elseif lowercase(frequency)=='m'
        as_r_ts_month(ta, "r_timeseries")
    else
        @error "incompatible frequency. Did you perhaps supply annual data?"
    end #if

    dates = timestamp(ta) # get Dates
    longdates = extend_timestamp(ta, lowercase(frequency)) # get Dates plus one year
    reval("x12res = x12::x12(r_timeseries)") # estimate X13

    x13Output = X13Output( # get output
        TimeArray(dates, rcopy(R"x12res@a1")),
        TimeArray(longdates, rcopy(R"x12res@d10")),
        TimeArray(dates, rcopy(R"x12res@d11")),
        TimeArray(dates, rcopy(R"x12res@d12")),
        TimeArray(dates, rcopy(R"x12res@d13")),
        TimeArray(longdates, rcopy(R"x12res@d16")),
        TimeArray(dates, rcopy(R"x12res@c17")),
        TimeArray(longdates, rcopy(R"x12res@d9")),
        TimeArray(dates, rcopy(R"x12res@e2")),
        TimeArray(longdates, rcopy(R"x12res@d8")),
        TimeArray(longdates, rcopy(R"x12res@b1")),
        rcopy(R"x12res@td"),
        rcopy(R"x12res@otl"),
        Spectrum(rcopy(R"x12res@sp0@frequency"), rcopy(R"x12res@sp0@spectrum")),
        Spectrum(rcopy(R"x12res@sp1@frequency"), rcopy(R"x12res@sp1@spectrum")),
        Spectrum(rcopy(R"x12res@sp2@frequency"), rcopy(R"x12res@sp2@spectrum")),
        Spectrum(rcopy(R"x12res@spr@frequency"), rcopy(R"x12res@spr@spectrum")),
        Fbcast(rcopy(R"x12res@forecast@estimate"), rcopy(R"x12res@forecast@lowerci"), rcopy(R"x12res@forecast@upperci")),
        Fbcast(rcopy(R"x12res@backcast@estimate"), rcopy(R"x12res@backcast@lowerci"), rcopy(R"x12res@backcast@upperci")),
        rcopy(R"x12res@dg"),
        rcopy(R"x12res@file"),
        rcopy(R"x12res@tblnames"),
        rcopy(R"x12res@Rtblnames")
    )
    return x13Output
end #function
x13(ta::TimeArray) = x13(ta, determine_freq(ta)) # determine frequency automatically
x13(array::AbstractArray, frequency::AbstractChar='q') = x13(TimeArray(array, frequency=frequency), frequency=frequency)

"""
Shortcut to only get the seasonally adjusted time series.
Output is a single TimeArray.
"""
function season_adjust(ta, frequency)
    return x13(ta, frequency).d11
end #function
season_adjust(ta) = x13(ta).d11

end # module
