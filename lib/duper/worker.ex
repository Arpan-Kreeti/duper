# A Worker process asks for a file path from the PathFinder server
# compute the hash of the corresponding file, and send the (path,hash) to the
# gatherer. At some point, there are no paths left, so it then sends a :done
# notification to the gatherer instead.

defmodule Duper.Worker do
  use GenServer, restart: :transient
  # We added a worker restart option here.
  # We made our Worker server transient this means that the supervisor will
  # not restart it if it terminates normally, but will restart it if it fails.

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  # We dont have any state for workers so we pass nil
  # Also after the worker is initialized we want to start processing files so we call
  # Process.send_after(self(), :do_one_file, 0)
  def init(:no_args) do
    Process.send_after(self(), :do_one_file, 0)
    {:ok, nil}
  end

  # We get the next file path from the PathFinder server and call add_result(file_path)
  def handle_info(:do_one_file, _) do
    Duper.PathFinder.next_path()
    |> add_result()
  end

  # If the file_path returned by the PathFinder server is nil it means there are no more files
  # So we send :done message to the Gatherer server and return :stop message with :normal exit reason
  defp add_result(nil) do
    Duper.Gatherer.done()
    {:stop, :normal, nil}
  end

  # If the file path returned by the PathFinder server is not nil we Calculate the hash of the file 
  # by calling hash_of_file_at(path), and send a message to theh gatherer with the file path and its hash
  # We return {noreply, nil} since we don't have any state for a worker
  defp add_result(path) do
    Duper.Gatherer.result(path, hash_of_file_at(path))
    send(self(), :do_one_file)
    {:noreply, nil}
  end

  # We calculate the hash of a file path. We use steams to lazily read a file and find its hash using 
  # erlangs crypto library
  defp hash_of_file_at(path) do
    File.stream!(path, [], 1024 * 1024)
    |> Enum.reduce(
      :crypto.hash_init(:md5),
      fn block, hash ->
        :crypto.hash_update(hash, block)
      end
    )
    |> :crypto.hash_final()
  end
end
