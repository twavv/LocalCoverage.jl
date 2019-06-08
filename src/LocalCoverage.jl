module LocalCoverage

using Coverage
using DocStringExtensions
import Pkg

export generate_coverage, open_coverage, clean_coverage

"Directory for coverage results."
const COVDIR = "coverage"

"Coverage tracefile."
const LCOVINFO = "lcov.info"

"""
$(SIGNATURES)

Open the HTML coverage results in a browser for `pkg` if they exist.

See [`generate_coverage`](@ref).
"""
function open_coverage(pkg)
    htmlfile = Pkg.dir(pkg, COVDIR, "index.html")
    if !isfile(htmlfile)
        @warn("Not found, run generate_coverage(pkg) first.")
        return nothing
    end
    try
        if Sys.isapple()
            run(`open $htmlfile`)
        elseif Sys.islinux() || Sys.isbsd()
            run(`xdg-open $htmlfile`)
        elseif Sys.iswindows()
            run(`start $htmlfile`)
        end
    catch e
        error("Failed to open the generated $(htmlfile)\n",
              "Error: ", sprint(Base.showerror, e))
    end
    nothing
end

"""
$(SIGNATURES)

Generate a coverage report for package `pkg`.

When `genhtml`, the corresponding external command will be called to generate a
HTML report. This can be found in eg the package `lcov` on Debian/Ubuntu.

`*.cov` files are near the source files as generated by Julia, everything else
is placed in `Pkg.dir(pkg, \"$(COVDIR)\")`. The summary is in
`Pkg.dir(pkg, \"$(COVDIR)\", \"$(LCOVINFO)\")`.

Use [`clean_coverage`](@ref) for cleaning.
"""
function generate_coverage(pkg; genhtml = true)
    Pkg.test(pkg; coverage = true)
    cd(Pkg.dir(pkg)) do
        coverage = Coverage.process_folder()
        isdir(COVDIR) || mkdir(COVDIR)
        tracefile = "$(COVDIR)/lcov.info"
        Coverage.LCOV.writefile(tracefile, coverage)
        if genhtml
            branch = strip(read(`git rev-parse --abbrev-ref HEAD`, String))
            title = "on branch $(branch)"
            run(`genhtml -t $(title) -o $(COVDIR) $(tracefile)`)
        end
    end
end

"""
$(SIGNATURES)

Clean up after [`generate_coverage`](@ref).
"""
function clean_coverage(pkg)
    Coverage.clean_folder(Pkg.dir(pkg))
    rm(Pkg.dir(pkg, COVDIR); force = true, recursive = true)
end

end # module
