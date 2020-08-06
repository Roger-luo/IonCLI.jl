struct PDTN{name} end

PDTN(name::String) = PDTN{Symbol(name)}()

macro PDTN_str(name::String)
    return PDTN{Symbol(name)}
end

Base.show(io::IO, ::PDTN{template}) where {template} = print(io, "Pre-defined Template Name Type ", string(template))

"""
create a project or package.

# Arguments

- `path`: path of the project you want to create

# Options

- `--user <name>`: your GitHub user name for this package.
- `--template <template name>`: template name, default template is "default".

# Flags

- `-i, --interactive`: enable to start interactive configuration interface.
"""
@cast function create(path; user="", interactive::Bool=false, template="default")
    if !isabspath(path)
        fullpath = joinpath(pwd(), path)
    else
        fullpath = path
    end

    if ispath(fullpath)
        error("$path exists, remove it or use a new path")
    end

    # TODO: use .ionrc to save user configuration
    # and reuse it next time
    if !interactive && isempty(user)
        error("user name is required, please either use --user <name> to specify it or create using -i, --interactive")
    end

    t = create_template(PDTN(template), dirname(fullpath), user, interactive)
    t(basename(fullpath))
    return
end
