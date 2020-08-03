function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    isdefined(IonCLI, Symbol("#create##kw")) && precompile(Tuple{getfield(IonCLI, Symbol("#create##kw")), NamedTuple{(:user, :template), Tuple{String, String}}, typeof(IonCLI.create), String})
    isdefined(IonCLI, Symbol("#fetch_repo##kw")) && precompile(Tuple{getfield(IonCLI, Symbol("#fetch_repo##kw")), NamedTuple{(:auth,), Tuple{GitHub.OAuth2}}, typeof(IonCLI.fetch_repo), Pkg.Types.RegistrySpec, Base.Dict{String, Any}})
    precompile(Tuple{typeof(IonCLI.command_main), Array{String, 1}})
    precompile(Tuple{typeof(IonCLI.create_template), IonCLI.PDTN{:unknown}, String, String})
    precompile(Tuple{typeof(IonCLI.is_version_number), String})
    precompile(Tuple{typeof(IonCLI.print_stars), Base.TTY, GitHub.Repo})
    precompile(Tuple{typeof(IonCLI.print_stars), GitHub.Repo})
    precompile(Tuple{typeof(IonCLI.search), String})
    precompile(Tuple{typeof(IonCLI.search_exact_package), String})
    precompile(Tuple{typeof(IonCLI.search_fuzzy_package), String})
end
