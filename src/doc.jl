"""
documentation tools.
"""
module Doc

using Comonicon
using LiveServer: servedocs

function with_ion_image(f, path::String=pwd())
    project_dir = dirname(Base.current_project(path))
    docs_dir = joinpath(project_dir, "docs")
    opts = Base.JLOptions()
    # we use Ion's image to accelerate loading time
    # of Documenter and fallback to default system image
    image_file = unsafe_string(opts.image_file)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())

    withenv("JULIA_PROJECT"=>docs_dir) do
        f(julia, image_file, docs_dir)
    end
end

"""
build documentation.

# Args

- `path`: path of the project.
"""
@cast function build(path::String=pwd())
    with_ion_image(path) do julia, image_file, docs_dir
        run(Cmd([julia, "-J$image_file", joinpath(docs_dir, "make.jl")]))
    end
end

"""
serve documentation.

# Options

- `--foldername <name>`: specify the name of the content folder if different than "docs".
- `--literate <path>`: is the path to the folder containing the literate scripts, if 
    left empty, it will be assumed that they are in docs/src.

# Flags

- `--verbose`: show verbose log.
- `--doc-env`: is a boolean switch to make the server start by activating the 
    doc environment or not (i.e. the Project.toml in docs/).
"""
@cast function serve(;verbose::Bool=false, literate="", foldername="docs")
    servedocs(;verbose=verbose, literate=literate, doc_env=true, foldername=abspath(foldername))
end

end

@cast Doc
