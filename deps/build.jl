using IonBase
using IonCLI
using Comonicon: Comonicon, PATH, Options, BuildTools

configs = Options.read_configs(IonCLI)
@info "building application"
BuildTools.build_application(IonCLI, configs)
IonBase.copy_assets(joinpath(pkgdir(IonCLI), "build", "ion"))
# pack tarball
tarball = BuildTools.tarball_name(IonCLI, configs.name; application = true)
@info "creating application tarball $tarball"
cd(PATH.project(IonCLI, configs.application.path)) do
    run(`tar -czvf $tarball $(configs.name)`)
end
