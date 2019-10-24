defmodule Tapestry.Routing do
  @doc """
  Build the routing table for a list of PIDs
  """
  def build_routing_tables(pids) do

    # Build a map that maps PIDs to hashes
    pid_hash_map = Enum.reduce(pids, %{}, fn pid, res ->
      Map.put(res, pid, encode_pid(pid))
    end)

    # Build the routing table
    routing_table = Enum.reduce(pid_hash_map, %{}, fn {my_pid, my_hash}, res ->
      pid_routing_table = build_routing_table(my_pid, my_hash, pid_hash_map)
      Map.put(res, my_pid, pid_routing_table)
    end)

    {pid_hash_map, routing_table}
  end

  @doc """
  Build the routing table of an individual PID
  """
  def build_routing_table(pid, hash, pid_hash_map) do
    Enum.reduce(pid_hash_map, %{},
      fn {other_pid, other_hash}, routing_table ->

      if other_pid != pid do
        {column, matching_prefix} = get_route_to(other_hash, hash)

        if Map.has_key?(routing_table, {column, matching_prefix}) do
          routing_table
        else
          Map.put(routing_table, {column, matching_prefix}, other_pid)
        end
      else
        # if other_pid == pid
        # Return the accumulated routing table as is
        routing_table
      end
    end)
  end

  def encode_pid(pid) do
    # Convert the PID to a 160 bit hash and encode it in Base16
    :crypto.hash(:sha, inspect(pid)) |> Base.encode16
  end

  def get_route_to(to_hash, from_hash) do
  
    # Both hashes are of the same length  
    indices = 0..String.length(to_hash) - 1
    
    first_neg_match_index = Enum.find_index(indices, fn i ->
      String.at(to_hash, i) != String.at(from_hash, i)
    end)

    matching_row = String.at(to_hash, first_neg_match_index)
    
    {first_neg_match_index, matching_row}
  end
end