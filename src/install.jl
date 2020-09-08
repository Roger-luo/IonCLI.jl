"""
install a given target. Currently only supports "path",
future will support installing a specific Julia version
and Comonicon applications.

# Arguments

- `target`: install given target, can be "path".
"""
@cast function install(target::String)
    if target == "path"
        comonicon_install_path()
    else
        error("unkown target: $target")
    end
    return
end
