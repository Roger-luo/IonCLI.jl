using IonCLI; IonCLI.comonicon_install()
using IonBase; IonBase.CreateCmd.copy_templates(joinpath(pkgdir(IonCLI), "build", "ion", "templates"))
