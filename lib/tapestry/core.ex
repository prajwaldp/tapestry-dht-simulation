defmodule Tapestry.Core do
  def create_nodes(num_nodes) do
    nodes = Enum.map(1..num_nodes, fn i ->
      Supervisor.child_spec(Tapestry.Node, id: i)
    end)

    opts = [strategy: :one_for_one, name: Tapestry.NodesSupervisor]
    Supervisor.start_link(nodes, opts)

    pids =
      Supervisor.which_children(Tapestry.NodesSupervisor)
      |> Enum.map(fn {_, pid, :worker, _} -> pid end)

    pids
  end
end
