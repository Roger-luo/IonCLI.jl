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
