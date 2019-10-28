# Elixir doesn’t have a filesystem-traversal API built in, so we look on ‘hex.pm‘
# and find dir_walker, which we just need to wrap in a trivial GenServer whose
# state is the directory walker’s PID. 

defmodule Duper.PathFinder do
  use GenServer

  # Start PathFinder server passing it the root path
  def start_link(root) do
    GenServer.start_link(__MODULE__, root, name: __MODULE__)
  end

  def next_path() do
    GenServer.call(__MODULE__, :next_path)
  end

  def init(path) do
    # Start the DirWalker server with the root path
    DirWalker.start_link(path)
    # The above call returns the DirWalkers pid which we stored 
    # as our initial state
  end

  def handle_call(:next_path, _from, dir_walker) do
    # Since we have the DirWalkers pid in our state we use it to make next() call on the Dirwalkers pid
    path =
      case DirWalker.next(dir_walker) do
        # Reutns the next file path (recursing if necessary) in the format [path]
        [path] -> path
        # Retuns nil when ther are no fore files to return
        other -> other
      end

    {:reply, path, dir_walker}
  end
end
