# {{{PKG}}}

{{#BADGES}}
{{{.}}}
{{/BADGES}}

## Installation
<p>
{{{PKG}}} is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://julialang.org/favicon.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install {{{PKG}}},
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command
</p>

For stable release

```julia
pkg> add {{{PKG}}}
```

For current master

```julia
pkg> add {{{PKG}}}#master
```

### Command Line Interface

Add `~/.julia/bin` to your `PATH` to enable command line interface. Or run
`{{{PKG}}}.comonicon_install_path()` to install everything automatically.

Sometimes, you won't trigger the package `build` of Julia. You can install the command line interface
manually via `{{{PKG}}}.comonicon_install()`.

### Completions

If you are using ZSH, you can enable the auto-completion by `{{{PKG}}}.comonicon_install_path()`. Or add the `FPATH`
to your `.zshrc`

```sh
export FPATH="$HOME/.julia/completions:$FPATH"
```

if you do not have [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) installed, you need to add

```sh
autoload -Uz compinit && compinit
```

to your `.zshrc` as well.

{{#HAS_CITATION}}
## Citing

See [`CITATION.bib`](CITATION.bib) for the relevant reference(s).
{{/HAS_CITATION}}
