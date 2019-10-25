defmodule Tapestry.Routing do
  @moduledoc """
  Contains functions for building the routing tables for processes,
  for encoding processes to hashes and for finding the route from
  one hash to another hash.
  """

  @doc """
  Build the routing table for a list of PIDs

  Returns a tuple, the first element is a Map of PIDs to their encoded hashes
  and the second element is a Map of PIDs to their routing table.
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

  Returns a map that represents the routing table.
  """
  def build_routing_table(pid, hash, pid_hash_map) do
    Enum.reduce(pid_hash_map, %{},
      fn {other_pid, other_hash}, routing_table ->

      if other_pid != pid do
        {column, matching_row} = get_route_to(other_hash, hash)

        if Map.has_key?(routing_table, {column, matching_row}) do

          # If the routing table of this node contains a route for this match,
          # the route is updated with the route to the node that is closer
          # to this node

          # `existing_route` is a pid
          existing_route = Map.get(routing_table, {column, matching_row})
          hash_for_existing_route = Tapestry.Routing.encode_pid(existing_route)

          old_dist = abs(String.to_integer(hash_for_existing_route, 16) -
            String.to_integer(hash, 16))

          new_dist = abs(String.to_integer(other_hash, 16) -
            String.to_integer(hash, 16))

          if new_dist < old_dist do
            Map.put(routing_table, {column, matching_row}, other_pid)
          else
            routing_table
          end
        
        else
          Map.put(routing_table, {column, matching_row}, other_pid)
        end
      else
        # if other_pid == pid
        # Return the accumulated routing table as is
        routing_table
      end
    end)
  end

  @doc """
  Encodes the process as a 40 digit hexadecimal string using the
  SHA1 hashing algorithm
  """
  def encode_pid(pid) do
    # Convert the PID to a 160 bit hash and encode it in Base16
    :crypto.hash(:sha, inspect(pid)) |> Base.encode16
  end

  @doc """
  Returns a tuple with the matching index and the column
  between to the two hashes.
  """
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
