open OUnit

module Kdt = Kd_tree.Make(
  struct 
    type t = float array

    let coord (x : t) = x
  end)

open Kdt

let random_point n = 
  Array.init n (fun _ -> Random.float 1.0)

let build_list n f = 
  let l = ref [] in 
    for i = n - 1 downto 0 do 
      l := (f i) :: !l
    done;
    !l

let random_tree n = 
  let objs = build_list n (fun _ -> random_point 2) in 
  let (low,high) = bounds_of_objects objs in 
    tree_of_objects objs low high

let in_bounds_p x low high = 
  let n = Array.length x in 
  let rec loop i = 
    (i = n) || 
      ((x.(i) >= low.(i)) && (x.(i) <= high.(i)) && (loop (i+1))) in 
    loop 0

let strict_in_bounds_p x low high = 
  let n = Array.length x in 
  let i = ref 0 and 
      inb = ref true in 
    while (!inb && !i < n) do 
      let x = x.(!i) in 
        if x < low.(!i) || x >= high.(!i) then inb := false;
        incr i
    done;
    !inb

let rec acceptable_tree_p = function 
  | Empty -> true
  | Cell(_, _, _,
         Empty, Empty) -> true
  | Cell(objs, _, _, 
         (Cell(_, llow, lhigh, _, _) as left), 
         (Cell(_, hlow, hhigh, _, _) as right)) -> 
      (List.for_all
         (fun obj ->
            let in_low = in_bounds_p obj llow lhigh and 
                in_high = in_bounds_p obj hlow hhigh in 
              (in_low || in_high) &&
                (not (in_low && in_high)))
         objs) && (acceptable_tree_p left) && (acceptable_tree_p right)
  | _ -> true

let rec depth = function 
  | Empty -> 0
  | Cell(_,_,_,left,right) -> 
      1 + (max (depth left)
             (depth right))

let test_tree_invariant () = 
  for i = 0 to 100 do 
    let t = random_tree 250 in 
      assert_bool "tree invariant violated" (acceptable_tree_p t)
  done

let test_tree_depth () = 
  let t = random_tree 1024 in 
  let d = depth t in
    assert_bool 
      (Printf.sprintf "depth of 1024 points not near 10, instead %d" d)
      ((8 <= d) && (d <= 12))

let log_multi_gaussian mu sigma x = 
  let lg = ref 0.0 in 
    for i = 0 to Array.length x - 1 do 
      lg := !lg +. Stats.log_gaussian mu.(i) sigma.(i) x.(i) 
    done;
    !lg +. 0.0

let random_jump delta = 
  Random.float delta -. (0.5*.delta)

let tests = "kd_tree.ml tests" >:::
  ["tree invariant" >:: test_tree_invariant;
   "tree depth" >:: test_tree_depth]
