using IonCLI; IonCLI.comonicon_install()
using IonBase; IonBase.copy_assets(joinpath(pkgdir(IonCLI), "build", "ion"))
