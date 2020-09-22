using IonCLI, IonBase, Comonicon
# help msgs
IonCLI.command_main(["-h"]);
for cmd in keys(IonCLI.CASTED_COMMANDS)
    if cmd != "main"
        IonCLI.command_main([cmd, "-h"]);
    end
end

cd(tempdir()) do
    rm("Foo"; recursive=true, force=true)
    IonCLI.command_main(["create", "Foo", "--user=xyz"])
    rm("Foo"; recursive=true, force=true)
    IonCLI.command_main(["create", "Foo", "--user=xyz", "--template=comonicon"])

    project = IonBase.Project(joinpath(pwd(), "Foo"), quiet=true)
    IonBase.update_version!(project, "0.2.0")
    IonBase.update_version!(project, "patch")
    IonBase.update_version!(project, "minor")
    IonBase.update_version!(project, "major")
    rm("Foo"; recursive=true, force=true)

    rm("IonBase"; recursive=true, force=true)
    IonCLI.command_main(["clone", "IonBase"])
    rm("IonBase"; recursive=true, force=true)    
end

IonCLI.command_main(["search", "Yao"])
IonBase.Doc.build(Comonicon.PATH.project(IonBase))
