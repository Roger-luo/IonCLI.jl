module IonCLI

using Comonicon
using PkgTemplates
using LocalRegistry
using RegistryTools
using GitHub
using OrderedCollections
using Pkg

using RegistryTools: gitcmd

# Julia Pkg commands
include("project.jl")
include("registry.jl")

# extra Ion commands
include("plugins/create.jl")
include("plugins/release.jl")
include("utils.jl")


@main name="ion" doc="The Ion manager."

end
