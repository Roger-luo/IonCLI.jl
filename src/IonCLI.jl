module IonCLI

using Comonicon
using Comonicon.Tools
using PkgTemplates
using LocalRegistry
using RegistryTools
using GitHub
using StringDistances
using OrderedCollections
using Pkg
using Pkg.TOML

using RegistryTools: gitcmd
using PkgTemplates: @plugin, @with_kw_noshow
using Comonicon.Parse: default_name

Comonicon.set_brief_length!(120)

# GITHUB_TOKEN is used in github actions
# GITHUB_AUTH is suggested by GitHub.jl
const ENV_TOKEN_NAMES = ["GITHUB_TOKEN", "GITHUB_AUTH"]


module PATH

using ..IonCLI

function default_ion_dir()
    if haskey(ENV, "DOT_ION_PATH")
        return ENV["DOT_ION_PATH"]
    else
        return joinpath(homedir(), ".ion")
    end
end

dot_ion(xs...) = joinpath(default_ion_dir(), xs...)

function templates(xs...)
    joinpath(dirname(dirname(pathof(IonCLI))), "templates", xs...)
end

end

# Julia Pkg commands
include("project.jl")
include("registry.jl")

# extra Ion commands
include("create.jl")
include(joinpath("templates", "default.jl"))
include(joinpath("templates", "command.jl"))
include(joinpath("templates", "from_file.jl"))

include("install.jl")
include("clone.jl")
include("doc.jl")
include("release.jl")
include("search.jl")
include("utils.jl")

"The Ion manager."
@main

include("precompile.jl")
_precompile_()

end
