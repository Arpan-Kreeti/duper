# The results server wraps an Elixir map. When it starts, it sets its state to an
# empty map. The keys of this map are hash values, and the values are the list of
# one of more paths whose files have that hash.
# The server provides two API calls: one to add a hash/path pair to the map, the
# second to retrieve entries that have more than one path in the value (as these are
# two duplicate files).

defmodule Duper.Results do
  use GenServer

  # API

  # Start the Duper Results server
  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  # Add a new key,value (hash,file path) entry to the results
  def add_hash_for(path, hash) do
    GenServer.cast(__MODULE__, {:add, path, hash})
  end

  # Find all duplicate files (files having same hash key)
  def find_duplicates() do
    GenServer.call(__MODULE__, :find_duplicates)
  end

  # SERVER

  def init(:no_args) do
    {:ok, %{}}
  end

  def handle_cast({:add, path, hash}, results) do
    results =
      Map.update(
        results,
        hash,
        [path],
        # The function is invoked with the exisiting value at key, if the key is already presesnt in the map. Thhe value that the function returns becomes the new value at key
        fn existing ->
          [path | existing]
        end
      )

    {:noreply, results}
  end

  def handle_call(:find_duplicates, _from, results) do
    {
      :reply,
      # This value will be send as reply to the client
      hashes_with_more_than_one_path(results),
      # This is the new state (it remains unchanged here)
      results
    }
  end

  defp hashes_with_more_than_one_path(results) do
    results
    # Iterate ove the map of (hash,file_path list) and chose those pairs where the file_pathh list has length>1 that is more than one files have same hash (duplicates) 
    |> Enum.filter(fn {_hash, paths} -> length(paths) > 1 end)
    # From each such map fetch the list, that is wet get a list of lists where each list element contains duplicate files like [["path3", "path1"], ["path5", "path2"]][["path3", "path1"], ["path5", "path2"]]
    |> Enum.map(&elem(&1, 1))
  end
end
