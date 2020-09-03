using Comonicon, IonCLI
try
    Comonicon.install(IonCLI)
catch err
    @warn "failed to download prebuilt sysimage" err
    @info "fallback to build sysimage in your local machine, this could take a few minutes"
    IonCLI.comonicon_build()
end
