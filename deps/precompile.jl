using IonCLI, IonBase, Comonicon, Pkg
# help msgs
IonCLI.command_main(["-h"]);
for cmd in keys(IonCLI.CASTED_COMMANDS)
    if cmd != "main"
        IonCLI.command_main([cmd, "-h"]);
    end
end

# path = tempdir()
# cd(path) do
#     rm("Foo"; recursive=true, force=true)
#     IonCLI.command_main(["create", "Foo", "--user=xyz"])
#     rm("Foo"; recursive=true, force=true)
#     IonCLI.command_main(["create", "Foo", "--user=xyz", "--template=comonicon"])

#     rm("IonBase"; recursive=true, force=true)
#     IonCLI.command_main(["clone", "IonBase"])
#     IonBase.Doc.build(joinpath(path, "IonBase"))
#     rm("IonBase"; recursive=true, force=true)    
# end

Pkg.activate(pkgdir(IonBase))
include(joinpath(pkgdir(IonBase), "test", "runtests.jl"))

module MISC

include(joinpath(pkgdir(IonBase), "test", "utils.jl"))

with_test_ion() do
    IonCLI.command_main(["search", "Yao"])
end

end
