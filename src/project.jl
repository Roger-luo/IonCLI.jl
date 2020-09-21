# This file only forward to Pkg's command but under --project by default

function withproject(command, glob, action_msg, compile_min=true)
    script = "using Pkg;"
    if !glob
        msg = "cannot $action_msg in global environment, use -g, --glob to $action_msg to global environment"
        script *= "(dirname(dirname(Pkg.project().path)) == joinpath(DEPOT_PATH[1], \"environments\")) && error(\"$msg\");"
    end

    script *= command

    exename = joinpath(Sys.BINDIR, Base.julia_exename())

    options = []
    if compile_min
        push!(options, "--compile=min")
    end
    push!(options, "-g1", "--color=yes", "--startup-file=no", "-e", script)

    if glob
        GLOB_ENV = filter(x->x.first!="JULIA_PROJECT", ENV)
        run(setenv(Cmd([exename, options...]), GLOB_ENV))
    else
        withenv("JULIA_PROJECT"=>"@.") do
            run(Cmd([exename, options...]))
        end
    end
    return
end


"""
add package/project to the closest project.

# Arguments

- `urls`: package names or urls to add.

# Flags

- `-g, --glob`: add package to global shared environment.

"""
@cast function add(urls...; glob::Bool=false)
    isempty(urls) && error("expect a package name or url")
    packages = join(urls, " ")

    withproject(
        "pkg\"add $packages\"",
        glob,
        "install a package",
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

    withproject(cmd, glob, "build", false)
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

    withproject(cmd, glob, "test", false)
end


"""
show current environment status

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
        cmd = "Pkg.status(\"$pkg\"; diff=$diff)"
    end

    withproject(cmd, glob, "show status")
end

"""
Update the current manifest. It will update manifest
with potential changes to the dependency graph from
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
@cast function rm(pkg, pkgs...; glob::Bool=false)
    withproject("pkg\"rm $(join([pkg, pkgs...], " "))\"", glob, "rm package")
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
    withproject("Pkg.free(\"$pkg\")", glob, "free $pkg")
end

# @cast function register()
# end
