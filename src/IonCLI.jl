module IonCLI

using Comonicon
using PkgTemplates
using LibGit2
using Pkg

include("project.jl")
include("registry.jl")
include("utils.jl")


@command_main name="ion" version="0.1.0" doc="""
The Ion manager.
"""

end
