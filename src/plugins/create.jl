"""
create a project or package.

# Arguments

- `path`: path of the project you want to create

# Flags

- `-i, --interactive`: enable to start interactive configuration interface.
"""
@cast function create(path; interactive::Bool=false)
    if !isabspath(path)
        fullpath = joinpath(pwd(), path)
    else
        fullpath = path
    end

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