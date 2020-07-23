# const REGISTRYS = Dict{String, Any}()

# struct RegistryIndex
#     index::Dict{String, Any}
# end

# RegistryIndex() = RegistryIndex(Dict{String, Any}())
# Base.setindex!(r::RegistryIndex, v, key::String) = r.index[key] = v

# function Base.getindex(r::RegistryIndex, key::String)
#     if haskey(r.index, key)
#         return r.index[key]
#     else
#         error("no method found to register packages in $key")
#     end
# end


Base.@kwdef struct VersionTokens
    major::String = "major"
    minor::String = "minor"
    patch::String = "patch"
end

const VERSION_TOKENS = VersionTokens()
Base.show(io::IO, vt::VersionTokens) = print(io, "(", vt.major, ", ", vt.minor, ", ", vt.patch, ")")

Base.in(version::String, tokens::VersionTokens) = (version == tokens.major) ||
    (version == tokens.minor) || (version == tokens.patch)

is_version_number(version) = occursin(r"[0-9]+.[0-9]+.[0-9]+", version)

struct Project
    path::String
    toml::String
    pkg::Pkg.Types.Project
    git::Cmd
    branch::String
end

function Project(path::String=pwd(); gitconfig=Dict(), branch="master")
    toml = Base.current_project(path)
    path = dirname(toml)
    pkg = Pkg.Types.read_project(toml)
    git = RegistryTools.gitcmd(path, gitconfig)
    return Project(path, toml, pkg, git, branch)
end

Base.show(io::IO, p::Project) = print(io, "Project(", p.path, ")")

function current_branch(p::Project)
    return readchomp(`$(p.git) rev-parse --abbrev-ref HEAD`)
end

function commit_toml(project::Project; push::Bool=false)
    git = project.git
    version_number = project.pkg.version
    run(`$git add $(project.toml)`)
    run(`$git commit -m"bump version to $version_number"`)

    if push
        run(`$git push origin master`)
    end
end

function reset_last_commit(project::Project)
    git = project.git
    run(`$git revert --no-edit HEAD`)
end

function checkout(f, p::Project)
    old = current_branch(p)

    if old != p.branch
        @info "checking out to $(p.branch)"
        run(`$(p.git) checkout $(p.branch)`)
    end

    f()

    if old != p.branch
        run(`$(p.git) checkout $old`)
    end
end

"""
release a package and tag a version

# Arguments

- `version`: version number you want to release, can be a specific version or either of $(VERSION_TOKENS)
- `path`: path to the project you want to release, default is the current working directory.

# Options

- `-r,--registry <registry name>`: registry you want to register the package,
    if the package has not been registered, ion will try to register
    the package in the General registry. Or the user needs to specify
    the registry to register using this option.

- `-b, --branch <branch name>`: branch you want to register, use master branch by default.
"""
@cast function release(version::String, path::String=pwd(); registry="", branch="master")
    project = Project(path; branch=branch)
    # new version needs to be pushed
    # so the JuliaRegistrator can find
    # it later
    checkout(project) do
        update_version!(project, version)
        commit_toml(project; push=true)
        try
            register(registry, project)
        catch e
            reset_last_commit(project)
            rethrow(e)
        end
    end
    return
end

function register(registry::String, project::Project)
    if isempty(registry) # registered package
        path = LocalRegistry.find_registry_path(nothing, project.pkg)
        if basename(path) == "General"
            return register_general(project)
        end
    end

    if registry == "General"
        return register_general(project)
    end
end

function register_general(project::Project)
    github_token = read_auth()
    auth = GitHub.authenticate(github_token)
    HEAD = read_head(project.git)
    comment_json = Dict{String, Any}(
        "body" => registrator_msg(project),
    )

    repo = github_repo(project.git)
    if repo === nothing
        error("not a GitHub repository")
    end

    comment = GitHub.create_comment(repo, HEAD, :commit; params=comment_json, auth=auth)
    println(comment)
    return
end

function registrator_msg(project)
    msg = "Released from [Ion CLI](https://github.com/Roger-luo/IonCLI.jl)\n"
    # msg *= "@JuliaRegistrator register"
    if project.branch == "master"
        return msg
    else
        return msg * " branch=$(project.branch)"
    end
end

function read_auth()
    if haskey(ENV, "GITHUB_AUTH")
        return ENV["GITHUB_AUTH"]
    else
        buf = Base.getpass("GitHub Access Token (https://github.com/settings/tokens)")
        auth = read(buf, String)
        Base.shred!(buf)
        return auth
    end
end

function read_head(git, branch="master")
    return readchomp(`$git rev-parse --verify HEAD`)
end

function read_remote_push(git, remote="origin")
    return readchomp(`$git config --get remote.$remote.url`)
end

function github_repo(git, remote="origin")
    url = read_remote_push(git, remote)
    github_https = "https://github.com/"
    github_ssh = "git@github.com:"
    if startswith(url, github_https)
        return url[length(github_https)+1:end]
    elseif startswith(url, github_ssh)
        return url[length(github_ssh)+1:end-4]
    else
        return
    end
end

function update_version!(project::Project, version)
    if is_version_number(version)
        version_number = VersionNumber(version)
    elseif version in VERSION_TOKENS
        version_number = bump_version(project, version)
    else
        error("invalid version $version")
    end

    write_version(project, version_number)
    return project
end

function bump_version(project::Project, token::String)
    if project.pkg.version === nothing
        return bump_version(v"0.0.0", token)
    else
        return bump_version(project.pkg.version, token)
    end
end

function bump_version(version::VersionNumber, token::String)
    if token == VERSION_TOKENS.major
        return VersionNumber(version.major+1, version.minor, version.patch)
    elseif token == VERSION_TOKENS.minor
        return VersionNumber(version.major, version.minor+1, version.patch)
    elseif token == VERSION_TOKENS.patch
        return VersionNumber(version.major, version.minor, version.patch+1)
    else
        error("invalid token $token")
    end
end

function write_version(project::Project, version::VersionNumber)
    project.pkg.version = version
    open(project.toml, "w+") do f
        Pkg.TOML.print(f, to_dict(project))
    end
end

to_dict(p::Project) = to_dict(p.pkg)

function to_dict(project::Pkg.Types.Project)
    project_keys = [:name, :uuid, :authors, :version, :deps, :compat, :extras, :targets]
    t = []
    for key in project_keys
        push_maybe!(t, project, key)
    end

    # write other part back
    for key in keys(project.other)
        if !(key in string.(project_keys))
            push!(t, project.other[key])
        end
    end
    return OrderedDict(t)
end

function push_maybe!(t::Vector, project::Pkg.Types.Project, name::Symbol)
    key = string(name)
    if hasfield(Pkg.Types.Project, name)
        member = getfield(project, name)
        if member !== nothing
            push!(t, key => member)
        end
    else
        member = get(project.other, key, nothing)
        if member !== nothing
            push!(t, key => member)            
        end
    end
    return t
end
