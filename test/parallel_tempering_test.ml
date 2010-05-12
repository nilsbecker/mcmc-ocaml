(** Tests the parallel-tempering code in mcmc.ml, which uses MPI to
    run a number of chains in parallel.  Execute with 

    mpiexec -n <number-of-processes> ./parallel_tempering_test.{native,byte}

    To get a good sample in TI, you should have at least 5 processes
    (recall that you are doing a Riemann integral with that number of
    points).

    The posterior being simulated is a 1-D gaussian; each chain stores
    its samples into the file pt_test_<beta>_samples.dat, and also
    prints to stdout the thermodynamic integration calculation of the
    evidence.
*)

let _ = 
  let inp = open_in_bin "/dev/random" in 
  let seed = input_binary_int inp in 
    close_in inp;
    Random.init seed

let rank = Mpi.comm_rank Mpi.comm_world

let log_likelihood x = Stats.log_gaussian 0.0 1.0 x
let log_prior x = if abs_float x <= 10.0 then log 0.1 else 0.0

let jump_proposal x = Mcmc.uniform_wrapping (-10.0) 10.0 1.0 x
let log_jump_prob x y = 0.0

let samples = 
  Mcmc.reset_nswap ();
  let nskip = 11 and 
      nsamp = 100000 and 
      nswap = 101 in
  Mcmc.pt_mcmc_array ~nskip:nskip nsamp nswap log_likelihood log_prior jump_proposal log_jump_prob 0.0

let _ = 
  let nswap = Mcmc.get_nswap () in 
    Printf.eprintf "Rank %d: number of swaps = %d\n%!" rank nswap

let _ = 
  let out = open_out ("pt_test_" ^ (string_of_float (Mcmc.pt_beta ())) ^ "_samples.dat") in 
    Read_write.write (fun x -> [| x |]) out samples;
    close_out out

let _ = 
  let evid = Mcmc.thermodynamic_integrate samples in 
    Printf.printf "Process %d: log evidence %g (true value %g)\n%!" rank evid (-2.99573)