# The gatherer servers as the link between the workers and the result server as it gathers results from the
# wrokers and sends them to the results server

defmodule Duper.Gatherer do
  use GenServer

  # API

  def start_link(worker_count) do
    GenServer.start_link(__MODULE__, worker_count, name: __MODULE__)
  end

  # Whenever a worker process finishes its work it calls done using this API function.
  # Once all the workers finish that is worker_count == 0 we stop the gatherer server and report the results
  def done() do
    GenServer.cast(__MODULE__, :done)
  end

  # Whenever a worker process finishes calculating hash for a file it calls this API function which inturn
  # calls  Duper.Results.add_hash_for(path, hash) to add the hash value to the results
  def result(path, hash) do
    GenServer.cast(__MODULE__, {:result, path, hash})
  end

  # SERVER

  # Starts the gatherer server with initial state set to worker_count
  # We dont want the worker sto start before the gathherer server is started
  # and initialized. To do this we use Process.send_after.

  # The init function uses send_after to tell the runtime to queue a message to this
  # server immediately (that is, after waiting 0 ms). When the init function exits, the
  # server is then free to pick up this message, which triggers the handle_info
  # callback, and the workers get started

  def init(worker_count) do
    Process.send_after(self(), :kickoff, 0)
    {:ok, worker_count}
  end

  # After the gather server has started we start the worker servers 
  # by using the WorkerSupervisor.
  # We add each of the workers using the add_worker() function we defined
  # in WorkerSupervisor
  def handle_info(:kickoff, worker_count) do
    1..worker_count
    |> Enum.each(fn _ -> Duper.WorkerSupervisor.add_worker() end)

    {:noreply, worker_count}
  end

  # :done keeps track of the number of running workers.
  #  As each signals it is done the count is decremented, until the last :done
  # is received, where we report the results and exit.

  def handle_cast(:done, _worker_count = 1) do
    report_results()
    System.halt(0)
  end

  def handle_cast(:done, worker_count) do
    {:noreply, worker_count - 1}
  end

  # This function is called by a worker via the result() API to add a result (file_path,hash) to
  # the results by calling the Results.add_hash_for() function of the Results server
  def handle_cast({:result, path, hash}, worker_count) do
    Duper.Results.add_hash_for(path, hash)
    {:noreply, worker_count}
  end

  # Called when the last worker has finished and send a :done message
  # It calls the find_duplicates() function of the results server which 
  # displays the duplicate files
  defp report_results() do
    IO.puts("Results:\n")

    Duper.Results.find_duplicates()
    |> Enum.each(&IO.inspect/1)
  end
end
