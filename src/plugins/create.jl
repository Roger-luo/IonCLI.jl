struct PDTN{name} end

PDTN(name::String) = PDTN{Symbol(name)}()

macro PDTN_str(name::String)
    return PDTN{Symbol(name)}
end

Base.show(io::IO, ::PDTN{template}) where {template} = print(io, "Pre-defined Template Name Type ", string(template))

function create_template(::PDTN"default", dir, user)
    return Template(;
        dir=dir,
        user=user,
    )
end

function create_template(::PDTN"command", dir, user)
    return Template(;
        dir=dir,
        user=user,
        plugins=[
        ]
    )
end

function create_template(::PDTN"test", dir, user)
    return Template(;
        dir=dir,
        user=user,
        plugins=[
            Git(;
                ignore=String[],
                name="Roger-luo",
                email="rogerluo.rl18@gmail.com",
            )
        ]
    )
end

create_template(::PDTN{template}, dir, user) where template = error("template $(template) not found")

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

    if interactive
        t = Template(;dir=dirname(fullpath), user=user, interactive=true)
        t(basename(path))
        return
    end

    # TODO: use .ionrc to save user configuration
    # and reuse it next time
    if isempty(user)
        error("user name is required, please either use --user <name> to specify it or create using -i, --interactive")
    end

    t = create_template(PDTN(template), dirname(fullpath), user)
    t(basename(fullpath))
    return
end
