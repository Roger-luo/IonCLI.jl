@cast function search(package; registry="General")
    for reg in Pkg.Types.collect_registries()
        data = Types.read_registry(joinpath(reg.path, "Registry.toml"))
        for (uuid, pkginfo) in data["packages"]
            name = pkginfo["name"]
            
        end
    end
end
