function create_template(t::PDTN{name}, dir, user, interactive) where name
    template = search_local_template(t)
    isnothing(template) && error("template $(name) not found")
    return template
end

function search_local_template(::PDTN{name}) where name
    template_dir = PATH.dot_ion("templates")
    ispath(template_dir) || return
    template = string(name)
    for dir in readdir(template_dir)
        if dir == template
            error("read/save local template is not supported yet")
            # return read_template(joinpath(template_dir, dir))
        end
    end
    return
end

# function read_template(path)
#     file = joinpath(path, "README.md")
#     plugins = []
#     if isfile(file)
#         push!(plugins, Readme(;file=file))
#     end

#     file = joinpath(path, "Project.toml")
    
# end
