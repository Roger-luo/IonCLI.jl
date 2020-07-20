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

function withproject(command, glob, msg)
    script = "using Pkg;"
    if !glob
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
        "cannot install to global environment, use -g, --glob to install a package to global environment"
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

    withproject(cmd, glob, "cannot update global environment, use -g, --glob to update global environment")
end

@doc Docs.doc(update)
@cast up(pkg="") = update(pkg)

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

    withproject(cmd, glob, "cannot build global environment, use -g, --glob to build global environment")
end

@cast function test(pkg=""; glob::Bool=false)
    if isempty(pkg)
        cmd = "Pkg.test()"
    else
        cmd = "Pkg.test(\"$pkg\")"
    end

    withproject(cmd, glob, "cannot test in global environment, use -g, --glob to test in global environment")
end

# @cast function register()
# end
