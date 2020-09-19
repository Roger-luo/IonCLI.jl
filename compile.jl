using SnoopCompile, Pkg
project = Pkg.project()
rm(joinpath(dirname(project.path), "src", "precompile.jl"); force=true)
open(joinpath(dirname(project.path), "src", "precompile.jl"), "w+") do io
    println(io, "_precompile_() = nothing")
end

### Log the compiles
# This only needs to be run once (to generate "/tmp/comonicon_compiles.log")

SnoopCompile.@snoopc ["--project=$(project.path)"] "/tmp/ion_compiles.log" begin
    using IonCLI, Comonicon
    include(Comonicon.PATH.project(IonCLI, "deps", "precompile.jl"))
    include(Comonicon.PATH.project(IonCLI, "test", "runtests.jl"))
    IonCLI.command_main(["search", "Yao"])
end

### Parse the compiles and generate precompilation scripts
# This can be run repeatedly to tweak the scripts

data = SnoopCompile.read("/tmp/ion_compiles.log")
pc = SnoopCompile.parcel(reverse!(data[2]))

open(joinpath(dirname(project.path), "src", "precompile.jl"), "w") do io
    if any(str->occursin("__lookup", str), pc[:IonCLI])
        println(io, lookup_kwbody_str)
    end
    println(io, "function _precompile_()")
    println(io, "    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing")
    for ln in sort(pc[:IonCLI])
        println(io, "    ", ln)
    end
    println(io, "end")
end

open(joinpath(dirname(project.path), "deps", "statements.jl"), "w+") do io
    for (k, v) in pc
        for ln in sort(v)
            println(io, ln)
        end
    end
end
