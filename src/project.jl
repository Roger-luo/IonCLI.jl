function project_path(path)
    if !isabspath(path)
        return joinpath(pwd(), path)
    else
        return path
    end
end

"""
create a project or package.

# Arguments

- `path`: path of the project you want to create

# Flags

- `-i, --interactive`: enable to start interactive configuration interface.
"""
@cast function create(path; interactive::Bool=false)
    fullpath = project_path(path)

    if ispath(fullpath)
        error("$path exists, remove it or use a new path")
    end

    if interactive
        t = Template(;dir=dirname(fullpath), interactive=true)
        t(basename(path))
    end

    # TODO: use .ionrc to save user configuration
    # and reuse it next time
    # TODO: scan username in git config
    t = Template(;dir=dirname(fullpath))
    t(basename(path))
    return
end

function default_clone_name(url)
    name, _ = splitext(basename(url)) # rm .git
    _name, ext = splitext(name)
    if ext == ".jl" # preserve other extension
        name = _name
    end
    return name
end

function withproject(command, glob, action_msg)
    script = "using Pkg;"
    if !glob
        msg = "cannot $action_msg in global environment, use -g, --glob to $action_msg to global environment"
        script *= "(dirname(dirname(dirname(Pkg.project().path))) in DEPOT_PATH) && error(\"$msg\");"
    end

    script *= command
    cmd = Cmd(["-e", script])

    if glob
        run(`$(Base.julia_cmd()) $cmd`)
    else
        withenv("JULIA_PROJECT"=>"@.") do
            run(`$(Base.julia_cmd()) $cmd`)
        end
    end
    return
end

"""
clone a package repo to a local directory.

# Arguments

- `url`: a remote or local url of the git repository.
- `to` : a local position, default to be the repository name (without .jl)

"""
@cast function clone(url, to=default_clone_name(url); credential="")
    LibGit2.clone(url, to)
    return
end

"""
add package/project to the closest project.

# Arguments

- `url`: package name or url to add.

# Options

- `-v, --version <version number>`: package version, default is the latest available version, or master branch for git repos.
- `--rev <branch/commit>`: git revision, can be branch name or commit hash.
- `-s, --subdir <subdir>`: subdir of the package.

# Flags

- `-g, --glob`: add package to global shared environment.

"""
@cast function add(url; version::String="", rev::String="", subdir::String="", glob::Bool=false)
    kwargs = []
    if isurl(url)
        push!(kwargs, "url=\"$url\"")
    else
        push!(kwargs, "name=\"$url\"")
    end

    !isempty(version) && push!(kwargs, "version=\"$version\"")
    !isempty(rev) && push!(kwargs, "rev=\"$rev\"")
    !isempty(subdir) && push!(kwargs, "subdir=\"$subdir\"")

    kw = join(kwargs, ", ")

    withproject(
        "Pkg.add(;$kw);",
        glob,
        "install a package"
    )
end

"""
Make a package available for development. If pkg is an existing local path, that path will be recorded in the manifest and used.
Otherwise, a full git clone of pkg is made. Unlike the `dev/develop` command in Julia REPL pkg mode, `ion` will clone the package
to the dev folder of the current project. You can specify `--shared` flag to use shared `dev` folder under `~/.julia/dev`
(specified by `JULIA_PKG_DEVDIR`).

# Arguments

- `url`: URL or local path to the package.

# Flags

- `-s, --shared`: controls whether to use the shared develop folder.

"""
@cast function dev(url; shared::Bool=false, glob::Bool=false)
    shared_flag = shared ? "--shared" : "--local"
    cmd = Cmd(["-e", "using Pkg; pkg\"dev $shared_flag $url\" "])
    withenv("JULIA_PROJECT"=>"@.") do
        run(`$(Base.julia_cmd()) $cmd`)
    end
end

"""
Update a package. If no posistional argument is given, update all packages in current project.

# Arguments

- `pkg`: package name.
"""
@cast function update(pkg=""; glob::Bool=false)
    if isempty(pkg)
        cmd = "pkg\"up\""
    else
        cmd = "pkg\"up $pkg\""
    end

    withproject(cmd, glob, "update dependencies")
end

"""
build package/project/environment

# Arguments

- `pkg`: package name.

# Flags

- `-v, --verbose`: print verbose log
- `-g, --glob`: enable to build in global shared environment
"""
@cast function build(pkg=""; verbose::Bool=false, glob::Bool=false)
    if isempty(pkg)
        cmd = "pkg\"build\""
    else
        cmd = "pkg\"build $pkg\""
    end

    withproject(cmd, glob, "build")
end

"""
test package/project

# Arguments

- `pkg`: package name.

# Flags

- `-g, --glob`: enable to test in global shared environment
"""
@cast function test(pkg=""; glob::Bool=false)
    if isempty(pkg)
        cmd = "Pkg.test()"
    else
        cmd = "Pkg.test(\"$pkg\")"
    end

    withproject(cmd, glob, "test")
end


"""
test package/project

# Arguments

- `pkg`: package name.

# Flags

- `-d, --diff`: show diff to last git commit
- `-g, --glob`: enable to show status in global shared environment
"""
@cast function status(pkg=""; diff::Bool=false, glob::Bool=false)
    if isempty(pkg)
        cmd = "Pkg.status(;diff=$diff)"
    else
        cmd = "Pkg.status($pkg; diff=$diff)"
    end

    withproject(cmd, glob, "show status")
end

"""
Update the current manifest with potential changes to the dependency graph from
packages that are tracking a path.

# Flags
- `-g, --glob`: enable to resolve in global shared environment
"""
@cast function resolve(; glob::Bool=false)
    withproject("Pkg.resolve()", glob, "resolve dependencies")
end

"""
Remove a package from the current project. If the mode of pkg is PKGMODE_MANIFEST also
remove it from the manifest including all recursive dependencies of pkg.

# Arguments

- `pkg`: package name to remove.

# Flags

- `-g, --glob`: enable to remove package in global shared environment
"""
@cast function rm(pkg; glob::Bool=false)
    withproject("Pkg.rm($pkg)", glob, "rm package")
end

"""
Undoes the latest change to the active project. Only states in the current session are
stored, up to a maximum of 50 states.

# Flags

- `-g, --glob`: enable to execute in global shared environment
"""
@cast undo(; glob::Bool=false) = withproject("Pkg.undo()", glob, "undo")

"""
Redoes the changes from the latest undo.

# Flags

- `-g, --glob`: enable to execute in global shared environment
"""
@cast redo(; glob::Bool=false) = withproject("Pkg.redo()", glob, "redo")

"""
If a Manifest.toml file exists in the active project, download all the packages
declared in that manifest. Otherwise, resolve a set of feasible packages from the
Project.toml files and install them. If no Project.toml exist
in the current active project, create one with all the dependencies in the manifest
and instantiate the resulting project.

# Flags

- `-v, --verbose`: prints the build output to stdout/stderr instead of redirecting to the build.log file.
"""
@cast function instantiate(;verbose::Bool=false)
    withproject("Pkg.instantiate(;verbose=$verbose)", false, "instantiate")
end

"""
If pkg is pinned, remove the pin. If pkg is tracking a path, e.g. after Pkg.develop,
go back to tracking registered versions.

# Flags

- `-g, --glob`: enable to execute in global shared environment

"""
@cast function free(pkg; glob::Bool=false)
    withproject("Pkg.free($pkg)", glob, "free $pkg")
end

# @cast function register()
# end
