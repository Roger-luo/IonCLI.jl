using IonCLI, Comonicon
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
    rm("Foo"; recursive=true, force=true)
end
