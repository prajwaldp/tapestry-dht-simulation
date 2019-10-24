defmodule Tapestry.API do
  def run_simulation(num_nodes, num_requests) do
    pids = Tapestry.Core.create_nodes(num_nodes)

    # Build an initial network with `num_nodes - 1` of the pids
    # The other node is later added to the network
    [pid_to_add | remaining_pids] = pids
    {pid_hash_map, routing_tables} = Tapestry.Routing.build_routing_tables(remaining_pids)

    # Set the hash and the routing table in the states of the `num_nodes - 1` nodes
    Enum.each(routing_tables, fn {node, rt} ->
      
      hash = Map.get(pid_hash_map, node)
      state = %{hash: hash, routing_table: rt}
      
      GenServer.call(node, {:set_state, state})
    end)

    # `num_nodes - 1` nodes have the routing table in their states now
    # Introducing another node into the network
    # `hash_to_add` is the hash of `pid_to_add`
    hash_to_add = Tapestry.Routing.encode_pid(pid_to_add)

    Enum.each(pid_hash_map, fn {pid, _} ->
      GenServer.call(pid, {:add_to_routing_table, hash_to_add, pid_to_add})
    end)

    # Update `pid_hash_map` with the new node and hash
    pid_hash_map = Map.put(pid_hash_map, pid_to_add, hash_to_add)

    pid_to_add_state = %{
      hash: hash_to_add,
      routing_table: Tapestry.Routing.build_routing_table(pid_to_add,
        hash_to_add, pid_hash_map)
    }

    GenServer.call(pid_to_add, {:set_state, pid_to_add_state})

    :rand.seed(:exsplus, {101, 102, 103})  # seed the random algorithm

    # Send `num_requests` requests from each node
    hash_list = Enum.map(pid_hash_map, fn {_pid, hash} -> hash end)
    
    Enum.each(pid_hash_map, fn {pid, from_hash} ->
      
      # Since there can be less number of nodes than the number
      # of requests each node has to make, the following approach
      # is discarded
      
      # requests_to_make = hash_list
      #   |> Enum.filter(fn to_hash -> to_hash != from_hash end)
      #   |> Enum.take_random(num_requests)

      other_hashes = Enum.filter(hash_list, fn to_hash -> to_hash != from_hash end)
      requests_to_make = Enum.reduce(1..num_requests, [], fn _, res ->
        [Enum.random(other_hashes)] ++ res
      end)
      
      send(pid, {:make_requests, requests_to_make, self()})
    end)

    wait_for_all_requests_to_complete(num_nodes * num_requests, 0)
  end

  def wait_for_all_requests_to_complete(num_requests, max_hop_count) do
    if num_requests > 0 do
      receive do
        {:done, hop_count} ->
          max_hop_count = if hop_count > max_hop_count do
            hop_count
          else
            max_hop_count
          end
          
          wait_for_all_requests_to_complete(num_requests - 1, max_hop_count)
      end
    else
      IO.puts "All requests completed. Max hops needed = #{max_hop_count}"
    end
  end
end