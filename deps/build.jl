using Comonicon, IonCLI
using Pkg.PlatformEngines

function download_sysimg()
    os = Sys.isapple() ? "darwin" :
        Sys.islinux() ? "linux" :
        error("unsupported OS")
    tarball_name = "ion-$(VERSION)-$os-$(Sys.ARCH).tar.gz"
    url = "https://github.com/Roger-luo/IonCLI.jl/releases/download/v0.1.4/$tarball_name"

    tarball = joinpath(Comonicon.PATH.project(IonCLI, "deps", tarball_name))
    PlatformEngines.probe_platform_engines!()
    try
        download(url, tarball)
        unpack(tarball, Comonicon.PATH.project(IonCLI, "deps"))
    finally
        rm(tarball)
    end
end

if "sysimg" in ARGS
    Comonicon.build(IonCLI, "ion"; filter_stdlibs=true, cpu_target="x86-64", create_tarball=true)
else
    download_sysimg()
    Comonicon.install(IonCLI, "ion"; compile=:min)
end
