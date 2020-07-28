using Comonicon, IonCLI

if "sysimg" in ARGS
    Comonicon.build(IonCLI, "ion"; sysimg=true, filter_stdlibs=true, cpu_target="x86-64")
else
    Comonicon.install(IonCLI, "ion"; compile=:min)
end
