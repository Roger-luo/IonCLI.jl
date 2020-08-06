@plugin struct SystemImage <: PkgTemplates.Plugin
    path::String="deps/lib"
    incremental::Bool=false
    filter_stdlibs::Bool=true
    cpu_target::String="x86-64"
end

@plugin struct ComoniconFiles <: PkgTemplates.Plugin
    name::Union{Nothing, String} = nothing
    # install
    completion::Bool=true
    quiet::Bool=false
    compile::Union{Nothing, String} = nothing
    optimize::Int=2
end

PkgTemplates.customizable(::Type{<:ComoniconFiles}) = [
    :name=>String,
    :completion=>Bool,
    :quiet=>Bool,
    :compile=>String,
    :optimize=>Int
]

PkgTemplates.customizable(::Type{<:SystemImage}) = [
    :path=>String,
    :incremental=>Bool,
    :filter_stdlibs=>Bool,
    :cpu_target=>String,
]

# set up deps
function PkgTemplates.prehook(::ComoniconFiles, ::Template, pkg_dir::AbstractString)
    if !ispath(joinpath(pkg_dir, "deps"))
        mkpath(joinpath(pkg_dir, "deps"))
    end
end

# create Comonicon.toml and build.jl
function PkgTemplates.hook(p::ComoniconFiles, t::Template, pkg_dir::AbstractString)
    suffix = ".jl"
    sysimg = nothing
    for each in t.plugins
        if (each isa PkgTemplates.Git) && (each.jl == false)
            suffix = ""
        end

        if each isa SystemImage
            sysimg = each
        end
    end

    pkg = basename(pkg_dir)
    toml = OrderedDict{String, Any}(
        "name" => isnothing(p.name) ? default_name(pkg) : p.name
    )

    toml["install"] = OrderedDict(
        "completion" => p.completion,
        "quiet" => p.quiet,
        "optimize" => p.optimize,
    )

    if !isnothing(p.compile)
        toml["install"]["compile"] = p.compile
    end

    # system image related files/configs
    if !isnothing(sysimg)
        toml["sysimg"] = OrderedDict(
            "path" => sysimg.path,
            "incremental" => sysimg.incremental,
            "filter_stdlibs" => sysimg.filter_stdlibs,
            "cpu_target" => sysimg.cpu_target,
        )

        toml["download"] = OrderedDict(
            "host" => t.host,
            "user" => t.user,
            "repo" => pkg * suffix,
        )
    end # system image related files/configs

    open(joinpath(pkg_dir, "Comonicon.toml"), "w") do f
        Pkg.TOML.print(f, toml)
    end

    open(joinpath(pkg_dir, "deps", "build.jl"); append=true) do f
        println(f, "using $pkg; $pkg.comonicon_install()")
    end
end

function PkgTemplates.hook(p::SystemImage, t::Template, pkg_dir::AbstractString)
    any(x->(x isa ComoniconFiles), t.plugins) || error("SystemImage plugin must be used with ComoniconFiles")
    workflow_dir = joinpath(pkg_dir, ".github", "workflows")
    mkpath(workflow_dir)
    cp(
        joinpath(
            PATH.templates("command", "github", "workflows", "sysimg.yml")
        ),
        joinpath(workflow_dir, "sysimg.yml")
    )
end

PkgTemplates.gitignore(::ComoniconFiles) = ["/deps/build.log"]
PkgTemplates.gitignore(::SystemImage) = ["/deps/lib", "/deps/precompile.jl"]
PkgTemplates.needs_username(::ComoniconFiles) = true

function create_template(::PDTN"comonicon", dir, user, interactive)
    return Template(;
        dir=dir,
        user=user,
        interactive=interactive,
        plugins=[
            Readme(;
                file = PATH.templates("command", "README.md"),
                destination="README.md",
                inline_badges=false
            ),
            ComoniconFiles(),
        ]
    )
end

function create_template(::PDTN"comonicon-sysimg", dir, user, interactive)
    return Template(;
        dir=dir,
        user=user,
        interactive=interactive,
        plugins=[
            Readme(;
                file = PATH.templates("command", "README.md"),
                destination="README.md",
                inline_badges=false
            ),
            ComoniconFiles(),
            SystemImage(),
        ]
    )
end
