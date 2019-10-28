# ---------------- FLOW -------------------

# It is very important that we start the servers in order since
# they depnend on each other so they will hang if not started in order.

# When the application starts, it will start the top-level supervisor
# by calling the start function in this file.
# This in turn starts Results, PathFinder, WorkerSupervisor, and Gatherer.
# When Gatherer starts (and it will start last), it tells the worker supervisor to start
# a number of workers. When each worker starts, it gets a path to process from
# PathFinder, hashes the corresponding file, and passes the result to Gatherer,
# which stores the path and the hash in the Results server. When there are no more
# files to process, each worker sends a :done message to the gatherer. When the last
# worker is done, the gatherer reports the results.

defmodule Duper.Application do
  use Application

  def start(_type, _args) do
    children = [
      # The Duper.Results server
      Duper.Results,
      # The Duper.PathFinder server with the current directory as the root path
      {Duper.PathFinder, "."},
      # The Duper.Supervisor server
      Duper.WorkerSupervisor,
      # The Duper.Gatherer server initialized with worker_count = 5
      {Duper.Gatherer, 5}
    ]

    # We have a supervison strategy of :one_for_all because in our child_spec list if 
    # The Results server fails we want the restart the whole application since all 
    # results so far have been lost similarly if the PathFinder, WorkerSupervisor or Gatherer
    # fails we must restart the  whole application as all progress will be lost.

    # Next since the supervision strategy for Workers is defined as :one_for_one
    # in the WorkerSupervisor we can say if a worker fails we have to restart only
    # that worker and nothing else.

    opts = [strategy: :one_for_all, name: Duper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
