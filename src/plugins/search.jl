"""
search a package.

# Options

- `--registry <name>`: the name of registry you want to search, by default will search all registry in default DEPOT_PATH
- `--token <github_token>`: specify GitHub authenticate token, this is necessary when you want to search frequently.

# Flags

- `--omit`: use this flag to print only the package names.
"""
@cast function search(package::String; omit::Bool=false, registry::String="", token::String="")
    results = search_fuzzy_package(package, registry)

    if (length(results) < 15) || Tools.prompt("display all $(length(results)) packages?")

        max_name_length = maximum(results) do (uuid, reg, pkginfo, score)
            length(pkginfo["name"])
        end

        auth = nothing
        if !omit
            if !isempty(token)
                auth = GitHub.authenticate(token)
            elseif haskey(ENV, "GITHUB_AUTH")
                auth = GitHub.authenticate(ENV["GITHUB_AUTH"])
            end
        end

        for (uuid, reg, pkginfo, score) in results
            name = pkginfo["name"]
            if omit
                println(name)
            else
                printstyled(name; color=:yellow)

                print(" "^(max_name_length - length(name)))
                print(" "^3)

                local repo
                try
                    if auth === nothing
                        repo = fetch_repo(reg, pkginfo)
                    else
                        repo = fetch_repo(reg, pkginfo; auth=auth)
                    end
                catch e # API rate limit exceeded
                    @warn "API rate limit exceeded can be fixed by setting GITHUB_TOKEN, or specify via --token"
                    rethrow(e)
                end

                print_stars(repo)
                println()
                printstyled("  ", repo.description; color=:light_blue)
                println()
            end
        end
    end
    return
end

function search_fuzzy_package(package::String, registry::String="")
    results = []
    for reg in Pkg.Types.collect_registries()
        if isempty(registry) || registry == reg.name
            data = Pkg.Types.read_registry(joinpath(reg.path, "Registry.toml"))
            for (uuid, pkginfo) in data["packages"]
                name = pkginfo["name"]
                score = compare(package, name, Overlap(length(package)); min_score = 0.6)
                if score >= 0.6
                    push!(results, (uuid, reg, pkginfo, score))
                end
            end
        end
    end
    sort!(results, by=x-> x[4]/length(x[3]["name"]), rev=true)
    return results
end

function search_exact_package(package::String, registry::String="")
    for reg in Pkg.Types.collect_registries()
        if isempty(registry) || registry == reg.name
            data = Pkg.Types.read_registry(joinpath(reg.path, "Registry.toml"))
            for (uuid, pkginfo) in data["packages"]
                name = pkginfo["name"]
                if name == package
                    return (uuid, reg, pkginfo)
                end
            end
        end
    end
    return nothing
end

function find_max_version(package::String, registry::String="")
    info = search_exact_package(package, registry)
    info === nothing && return

    uuid, reg, pkginfo = info
    versions = TOML.parsefile(joinpath(reg.path, pkginfo["path"], "Versions.toml"))
    max_version = findmax(VersionNumber.(keys(versions)))[1]
    return max_version
end

function fetch_repo(name; options...)
    result = search_exact_package(name)
    result === nothing && return
    _, reg, pkginfo = result
    return fetch_repo(reg, pkginfo; options...)
end

function fetch_repo(reg, pkginfo; options...)
    pkg = TOML.parsefile(joinpath(reg.path, pkginfo["path"], "Package.toml"))
    url = pkg["repo"]

    HTTPS_GITHUB = "https://github.com/"
    GIT_GITHUB = "git@github.com:"
    if startswith(url, HTTPS_GITHUB) && endswith(url, ".git")
        repo = GitHub.repo(url[length(HTTPS_GITHUB)+1:end-4]; options...)
    elseif startswith(url, GIT_GITHUB) && endswith(url, ".git")
        repo = GitHub.repo(url[length(GIT_GITHUB)+1:end-4]; options...)
    else
        return "not a GitHub repo, please visit $(url) for details about this package"
    end

    return repo
end

print_stars(repo) = print_stars(stdout, repo)
print_stars(io, repo) = print_stars(io, repo.stargazers_count)

function print_stars(io, nstars::Int)
    nds = ndigits(nstars)

    if nds < 4
        print(io, " "^(3 - nds), nstars)
    else
        first_three = string(nstars)[1:3]
        if  4 < nds < 7
            print(io, first_three, "K")
        elseif 7 <= nds < 10
            print(io, first_three, "M")
        elseif 10 <= nds < 13
            print(io, first_three, "B")
        else
            print(io, first_three, "e", nds - 3)
        end    
    end

    print(io, " stars")
end
