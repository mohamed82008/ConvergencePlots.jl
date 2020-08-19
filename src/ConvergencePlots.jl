module ConvergencePlots

export  ConvergencePlot,
        add_point!,
        update_plot!,
        closeplot!

using PyPlot, Parameters

mutable struct ConvergencePlot
    fig
    ax
    history::Dict
    options::Dict
    npoints::Int
end
function ConvergencePlot(
    npoints::Int = 100000;
    names = ["Residual"],
    options = nothing,
    show = false,
)
    history = Dict(n => Float64[] for n in names)
    if options === nothing
        options = Dict(n => (label = n,) for n in names)
    end
    @assert keys(history) == keys(options)
    fig, ax = emptyplot()
    if show
        PyPlot.show(block=false)
    end
    return ConvergencePlot(fig, ax, history, options, npoints)
end
function add_point!(plot::ConvergencePlot, y::Real; show = true)
    @assert length(keys(plot.history)) == 1
    k = collect(keys(plot.history))[1]
    return add_point!(plot, Dict(k => y), show = show)
end
function add_point!(plot::ConvergencePlot, y::Dict; show = true)
    @unpack fig, ax, history, npoints = plot
    for k in keys(y)
        if length(history[k]) < npoints
            push!(history[k], y[k])
        else
            history[k][1:n-1] .= history[k][2:n]
            history[k][n] = y[k]
        end
    end
    update_plot!(plot; show = show)
    return plot
end
function update_plot!(plot::ConvergencePlot; show = true)
    @unpack fig, ax, history, options = plot
    keepinteractive() do
        ax.clear()
        for k in keys(history)
            ax.plot(1:length(history[k]), history[k]; options[k]...)
        end
        fig.canvas.draw()
        fig.legend(loc=2)
        if show
            PyPlot.show(block=false)
        end
    end
    return plot
end
function closeplot!(plot::ConvergencePlot)
    PyPlot.close(plot.fig)
    fig, ax = emptyplot()
    @pack! plot = fig, ax
    return plot
end
function emptyplot()
    local fig, ax
    keepinteractive() do
        fig = PyPlot.figure()
        ax = fig.add_subplot(111)
        PyPlot.xlabel("Iteration")
    end
    return fig, ax
end
function keepinteractive(f)
    was_interactive = PyPlot.isinteractive()
    was_interactive && PyPlot.ioff()
    f()
    was_interactive && PyPlot.ion()
end

end
