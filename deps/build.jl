using Comonicon, IonCLI

if "sysimg" in ARGS
    Comonicon.build(IonCLI, "ion"; filter_stdlibs=true, cpu_target="x86-64", create_tarball=true)
else
    Comonicon.install(IonCLI, "ion"; compile=:min)
end
