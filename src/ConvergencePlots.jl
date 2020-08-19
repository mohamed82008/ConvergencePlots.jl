module ConvergencePlots

export  ConvergencePlot,
        add_point!,
        update_plot!,
        closeplot!

using PyPlot, Parameters

mutable struct ConvergencePlot
    fig
    ax
    axtwin
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
    elseif options isa Dict
        options = Dict(
            n => haskey(options[n], :label) ? options[n] : merge(options[n], (label = n,))
            for n in keys(options)
        )
    else
        options = Dict(n => merge(options, (label = n,)) for n in names)
    end
    # Fix the same color problem when using 2 y-axes
    if length(names) == 2
        n1, n2 = names
        if !(haskey(options[n2], :color))
            if haskey(options[n1], :color)
                color = options[n1].color == "tab:red" ? "tab:blue" : "tab:red"
            else
                color = "tab:red"
            end
            options = Dict(n1 => options[n1], n2 => merge(options[n2], (color = color,)))
        end
        if !(haskey(options[n1], :color))
            if haskey(options[n2], :color)
                color = options[n2].color == "tab:red" ? "tab:blue" : "tab:red"
            else
                color = "tab:red"
            end
            options = Dict(n1 => merge(options[n1], (color = color,)), n2 => options[n2])
        end
    end
    @assert keys(history) == keys(options)
    fig, ax, axtwin = emptyplot()
    if show
        PyPlot.show(block=false)
    end
    return ConvergencePlot(fig, ax, axtwin, history, options, npoints)
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
    @unpack fig, ax, axtwin, history, options = plot
    keepinteractive() do
        ax.clear()
        axtwin.clear()
        if length(keys(history)) == 2
            k1, k2 = collect(keys(history))

            ax.plot(1:length(history[k1]), history[k1]; options[k1]...)
            ax.set_ylabel(k1)
            ax.tick_params(axis="y", labelcolor=options[k1].color)

            axtwin.plot(1:length(history[k2]), history[k2]; options[k2]...)
            axtwin.set_ylabel(k2)
            axtwin.tick_params(axis="y", labelcolor=options[k2].color)
        else
            for k in keys(history)
                ax.plot(1:length(history[k]), history[k]; options[k]...)
            end
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
    fig, ax, axtwin = emptyplot()
    @pack! plot = fig, ax, axtwin
    return plot
end
function emptyplot()
    local fig, ax, axtwin
    keepinteractive() do
        fig = PyPlot.figure()
        ax = fig.add_subplot(111)
        ax.set_xlabel("Iteration")
        axtwin = ax.twinx()
    end
    return fig, ax, axtwin
end
function keepinteractive(f)
    was_interactive = PyPlot.isinteractive()
    was_interactive && PyPlot.ioff()
    f()
    was_interactive && PyPlot.ion()
end

end
