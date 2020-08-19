module ConvergencePlots

export  ConvergencePlot,
        add_point!,
        update_plot!,
        closeplot!

using PyPlot, Parameters, Random

mutable struct ConvergencePlot
    fig
    axs
    names::Vector{String}
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
    options = getoptions(names, options)
    @assert keys(history) == keys(options)
    fig, axs = emptyplot(length(names))
    if show
        PyPlot.show(block=false)
    end
    return ConvergencePlot(fig, axs, names, history, options, npoints)
end

function add_point!(plot::ConvergencePlot, y::Real; show = true)
    @assert length(keys(plot.history)) == 1
    k = collect(keys(plot.history))[1]
    return add_point!(plot, Dict(k => y), show = show)
end
function add_point!(plot::ConvergencePlot, y::Dict; show = true)
    @unpack history, npoints = plot
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
    @unpack fig, axs, names, history, options = plot
    keepinteractive() do
        for ax in axs
            ax.clear()
        end
        for i in 1:length(names)
            ax = axs[i]
            n = names[i]
            ax.plot(1:length(history[n]), history[n]; options[n]...)
            if mod(i, 2) == 1
                ax.set_xlabel("Iteration")
            end
            ax.set_ylabel(n)
            ax.tick_params(axis="y", labelcolor=options[n].color)
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
    fig, axs = emptyplot(length(plot.names))
    @pack! plot = fig, axs
    return plot
end

function emptyplot(ncurves)
    if ncurves % 2 == 0
        nsubplots = (ncurves ÷ 2)
    else
        nsubplots = (ncurves ÷ 2) + 1
    end
    local fig, axs
    keepinteractive() do
        fig, axs1 = PyPlot.subplots(nsubplots)
        axs = []
        for i in 1:nsubplots
            ax1 = nsubplots == 1 ? axs1 : axs1[i]
            push!(axs, ax1)
            if 2i <= ncurves
                ax2 = ax1.twinx()
                push!(axs, ax2)
            end
        end
    end
    return fig, axs
end

randcolor(rng) = (rand(rng), rand(), rand()) .* 0.7

function getoptions(names, old_options)
    rng = Random.MersenneTwister()
    Random.seed!(rng, 12344321)

    options = Dict()
    if old_options === nothing
        for n in names
            options[n] = (label = n,)
        end
    elseif old_options isa Dict
        for n in names
            if !(haskey(old_options[n], :label))
                options[n] = merge(old_options[n], (label = n,))
            end
        end
    else # Same options for all names
        for n in names
            options[n] = merge(old_options, (label = n,))
        end
    end

    # Fix the same color problem when using 2 y-axes
    for i in 1:(length(names) ÷ 2)
        n1, n2 = names[2i - 1], names[2i]
        if !(haskey(options[n2], :color))
            color = randcolor(rng)
            options[n2] = merge(options[n2], (color = color,))
        end
        if !(haskey(options[n1], :color))
            color = randcolor(rng)
            options[n1] = merge(options[n1], (color = color,))
        end        
    end
    if mod(length(names), 2) == 1
        n = names[end]
        if !(haskey(options[n], :color))
            color = randcolor(rng)
            options[n] = merge(options[n], (color = color,))
        end
    end
    return options
end

function keepinteractive(f)
    was_interactive = PyPlot.isinteractive()
    was_interactive && PyPlot.ioff()
    f()
    was_interactive && PyPlot.ion()
end

end
