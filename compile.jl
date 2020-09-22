using SnoopCompile, Pkg
project_path = dirname(@__FILE__)
rm(joinpath(project_path, "src", "precompile.jl"); force=true)
open(joinpath(project_path, "src", "precompile.jl"), "w+") do io
    println(io, "_precompile_() = nothing")
end

### Log the compiles
# This only needs to be run once (to generate "/tmp/comonicon_compiles.log")

SnoopCompile.@snoopc ["--project=$(project_path)"] "/tmp/ion_compiles.log" begin
    using IonCLI, Comonicon
    include(Comonicon.PATH.project(IonCLI, "deps", "precompile.jl"))
    include(Comonicon.PATH.project(IonCLI, "test", "runtests.jl"))
    IonCLI.command_main(["search", "Yao"])
end

### Parse the compiles and generate precompilation scripts
# This can be run repeatedly to tweak the scripts

data = SnoopCompile.read("/tmp/ion_compiles.log")
pc = SnoopCompile.parcel(reverse!(data[2]))

open(joinpath(project_path, "deps", "statements.jl"), "w+") do io
    for (k, v) in pc
        for ln in sort(v)
            println(io, ln)
        end
    end
end
