defmodule Tapestry.Node do
  use GenServer

  def start_link(_state) do
    # Set initial state to an empty Map
    GenServer.start_link(__MODULE__, %{})
  end

  # Callbacks
  
  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:set_state, new_state}, _from, _state) do
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:add_to_routing_table, hash, pid}, _from, state) do
    current_routing_table = state[:routing_table]
    {column, matching_prefix} = Tapestry.Routing.get_route_to(hash, state[:hash])
    
    new_routing_table = if Map.has_key?(current_routing_table, {column, matching_prefix}) do
      # Return the current routing table as it is
      current_routing_table
    else
      # Return the current table with the new hash and pid
      Map.put(current_routing_table, {column, matching_prefix}, pid)
    end

    state = Map.put(state, :routing_table, new_routing_table)
    
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:receive_request, destination, hop_count, path, callback_pid}, state) do
    if state[:hash] == destination do
      # IO.puts "Done in #{hop_count} hop(s), path = #{path} -> #{state[:hash]}"
      send(callback_pid, {:done, hop_count})
    else
      forward_address_key = Tapestry.Routing.get_route_to(destination, state[:hash])
      
      if Map.has_key?(state[:routing_table], forward_address_key) do
        forward_address = Map.get(state[:routing_table], forward_address_key)

        path = if path == "", do: state[:hash], else: path <> " -> " <> state[:hash]
        
        GenServer.cast(forward_address,
          {:receive_request, destination, hop_count + 1, path, callback_pid})
      else
        IO.puts "Oops! #{inspect forward_address_key} not in routing table of #{inspect self()}\nState: #{inspect state}"
      end
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:make_requests, requests, callback_pid}, state) do
    [request | remaining_requests] = requests

    GenServer.cast(self(), {:receive_request, request, 0, "", callback_pid})

    schedule_next_send(remaining_requests, callback_pid)
    {:noreply, state}
  end

  defp schedule_next_send(remaining_requests, callback_pid) do
    if length(remaining_requests) >= 1 do
      Process.send_after(self(), {:make_requests, remaining_requests, callback_pid}, 1_000)
    end
  end
end
