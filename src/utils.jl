# Copied from IsURL.jl
# Source: https://github.com/sindresorhus/is-absolute-url (MIT license)
const windowsregex = r"^[a-zA-Z]:[\\]"
const urlregex = r"^[a-zA-Z][a-zA-Z\d+\-.]*:"

"""
    isurl(str)
Checks if the given string is an absolute URL.
# Examples
```julia-repl
julia> isurl("https://julialang.org")
true
julia> isurl("mailto:someone@example.com")
true
julia> isurl("/foo/bar")
false
```
"""
function isurl(str::AbstractString)
    return !occursin(windowsregex, str) && occursin(urlregex, str)
end

function isgithub(url::AbstractString)
    if startswith(url, "http") && startswith(split(url, "//")[2], "github.com")
        return true
    else
        return false
    end
end
