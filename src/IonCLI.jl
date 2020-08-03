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

Comonicon.set_brief_length!(120)

# Julia Pkg commands
include("project.jl")
include("registry.jl")

# extra Ion commands
include("plugins/create.jl")
include("plugins/release.jl")
include("plugins/search.jl")
include("utils.jl")


@main name="ion" doc="The Ion manager."

end
