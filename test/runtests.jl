using IonCLI
using Comonicon.PATH
using Test
using Pkg

@testset "create & release" begin

@test IonCLI.is_version_number("0.1.0")
@test IonCLI.is_version_number("v0.1.0")

@test_throws ErrorException IonCLI.command_main(["create", PATH.project(IonCLI, "test", "dummy2"), "--user=Roger-luo", "--template=unknown"])

    dummy_project = PATH.project(IonCLI, "test", "dummy")
    rm(dummy_project, recursive=true, force=true)
    IonCLI.command_main(["create", dummy_project, "--user=Roger-luo", "--template=test"])
    project = IonCLI.Project(dummy_project, quiet=true)
    @test project.pkg.version == v"0.1.0"
    @test project.path == dummy_project

    IonCLI.update_version!(project, "0.2.0")
    @test project.pkg.version == v"0.2.0"
    @test Pkg.Types.read_project(joinpath(dummy_project, "Project.toml")).version == v"0.2.0"

    IonCLI.update_version!(project, "patch")
    @test project.pkg.version == v"0.2.1"
    @test Pkg.Types.read_project(joinpath(dummy_project, "Project.toml")).version == v"0.2.1"

    IonCLI.update_version!(project, "minor")
    @test project.pkg.version == v"0.3.0"
    @test Pkg.Types.read_project(joinpath(dummy_project, "Project.toml")).version == v"0.3.0"

    IonCLI.update_version!(project, "major")
    @test project.pkg.version == v"1.0.0"
    @test Pkg.Types.read_project(joinpath(dummy_project, "Project.toml")).version == v"1.0.0"

end

@testset "search" begin
    @test first(IonCLI.search_fuzzy_package("Yao"))[3]["name"] == "Yao"
    @test IonCLI.search_exact_package("Yao")[end]["name"] == "Yao"
    @test IonCLI.search_exact_package("ASDWXCASDSAS") === nothing
end

@testset "template/comonicon" begin
    test_comonicon = PATH.project(IonCLI, "test", "Foo")
    rm(test_comonicon; recursive=true, force=true)
    IonCLI.create(test_comonicon; user="Roger-luo", template="comonicon")
    comonicon_toml = joinpath(test_comonicon, "Comonicon.toml")
    @test isfile(comonicon_toml)
    toml = Pkg.TOML.parsefile(comonicon_toml)
    @test toml["name"] == "foo"
    @test toml["install"]["optimize"] == 2
    @test toml["install"]["quiet"] == false
    @test toml["install"]["completion"] == true
    @test isfile(joinpath(test_comonicon, "deps", "build.jl"))
end

@testset "template/comonicon-sysimg" begin
    test_comonicon = PATH.project(IonCLI, "test", "Foo")
    rm(test_comonicon; recursive=true, force=true)
    IonCLI.create(test_comonicon; user="Roger-luo", template="comonicon-sysimg")
    comonicon_toml = joinpath(test_comonicon, "Comonicon.toml")
    @test isfile(comonicon_toml)
    toml = Pkg.TOML.parsefile(comonicon_toml)
    @test toml["name"] == "foo"
    @test toml["sysimg"]["filter_stdlibs"] == true
    @test toml["sysimg"]["cpu_target"] == "x86-64"
    @test toml["sysimg"]["incremental"] == false
    @test toml["sysimg"]["path"] == "deps/lib"

    @test toml["download"]["repo"] == "Foo.jl"
    @test toml["download"]["host"] == "github.com"
    @test toml["download"]["user"] == "Roger-luo"
end
