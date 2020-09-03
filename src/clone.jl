"""
clone a package or url and setup the local repo. If the current local
git user do not have push access to remote github repo, it will fork
this repo then clone the repo and set the input url as upstream.

# Arguments

- `url_or_package`: name of the package or url.
"""
@cast function clone(url_or_package::String)
    if isurl(url_or_package)
        clone_url(url_or_package)
    else
        clone_package(url_or_package)
    end
    return
end

function clone_url(url::String)
    if endswith(url, "jl.git")
        _clone(url, basename(url)[1:end-7])
    else
        _clone(url, basename(url))
    end
end

function clone_package(package::String)
    info = search_exact_package(package)
    isnothing(info) && error("cannot find $package in registries")
    uuid, reg, pkginfo = info
    pkg_toml = Pkg.TOML.parsefile(joinpath(reg.path, pkginfo["path"], "Package.toml"))
    _clone(pkg_toml["repo"], pkg_toml["name"])
end

function _clone(url::String, to::String)
    username = readchomp(`git config user.name`)
    rp = fetch_repo_from_url(url)
    auth = GitHub.authenticate(read_auth())

    local has_access
    try
        has_access = iscollaborator(rp, username; auth=auth)
    catch e
        has_access = false
    end

    if has_access
        git_clone(url, to)
    else
        owned_repo = fork_repo(rp, auth)
        git_clone(owned_repo.clone_url.uri, to)
        set_upstream(url, to)
    end
end

function fork_repo(repo, auth)
    return create_fork(repo; auth=auth)
end

function set_upstream(url::String, to::String)
    cd(joinpath(pwd(), to)) do
        run(`git remote add upstream $url`)
        run(`git fetch upstream`)
        run(`git branch --set-upstream-to=upstream/master`)
    end
end

function git_clone(url, to)
    run(`git clone $url $to`)
end
