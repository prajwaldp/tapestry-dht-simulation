defmodule Tapestry.CLI do
  def run() do

    args = System.argv()

    if length(args) != 2 do
      IO.puts ">> Usage: mix run project3.exs <num_nodes> <num_requests>"
      IO.puts "or"
      IO.puts ">> mix escript.build"
      IO.puts ">> project3 <num_nodes> <num_requests>"
      
      exit :shutdown
    end

    num_nodes = Enum.at(args, 0) |> String.to_integer
    num_requests = Enum.at(args, 1) |> String.to_integer
    
    Tapestry.API.run_simulation(num_nodes, num_requests)
  end
end