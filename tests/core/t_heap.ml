open CCHeap
module T = (val Containers_testlib.make ~__FILE__ ())
include T

(* A QCheck generator for natural numbers that are not too large (larger than
 * [small_nat] but smaller than [big_nat]), with a bias towards smaller numbers.
 * This also happens to be what QCheck uses for picking a length for a list
 * generated by [QCheck.list].
 * QCheck defines this generator under the name [nat] but does not expose it. *)
let medium_nat =
  Q.make ~print:Q.Print.int ~shrink:Q.Shrink.int ~small:(fun _ -> 1)
    (fun st ->
       let p = Random.State.float st 1. in
       if p < 0.5 then Random.State.int st 10
       else if p < 0.75 then Random.State.int st 100
       else if p < 0.95 then Random.State.int st 1_000
       else Random.State.int st 10_000
    )

module H = CCHeap.Make (struct
  type t = int
  let leq x y = x <= y
end)

;;

t ~name:"of_list, take_exn" @@ fun () ->
  let h = H.of_list [ 5; 4; 3; 4; 1; 42; 0 ] in
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 0 x;
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 1 x;
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 3 x;
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 4 x;
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 4 x;
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 5 x;
  let h, x = H.take_exn h in
  assert_equal ~printer:string_of_int 42 x;
  assert_raises ((=) H.Empty) (fun () -> H.take_exn h);
  true
;;

q ~name:"of_list, to_list"
  ~count:30
  Q.(list medium_nat)
  (fun l ->
    (l |> H.of_list |> H.to_list |> List.sort CCInt.compare)
    = (l |> List.sort CCInt.compare))
;;

q ~name:"of_list, to_list_sorted"
  ~count:30
  Q.(list medium_nat)
  (fun l ->
    (l |> H.of_list |> H.to_list_sorted)
    = (l |> List.sort CCInt.compare))
;;

(* The remaining tests assume the correctness of
   [of_list], [to_list], [to_list_sorted]. *)

q ~name:"size"
  ~count:30
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    (l |> H.of_list |> H.size)
    = (l |> List.length))
;;

q ~name:"filter"
  Q.(list medium_nat)
  (fun l ->
    let p = (fun x -> x mod 2 = 0) in
    let l' = l |> H.of_list |> H.filter p |> H.to_list in
    List.for_all p l' && List.length l' = List.length (List.filter p l))
;;

q ~name:"of_gen"
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    (l |> CCList.to_gen |> H.of_gen |> H.to_list_sorted)
    = (l |> List.sort CCInt.compare))
;;

q ~name:"to_gen"
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    (l |> H.of_list |> H.to_gen |> CCList.of_gen |> List.sort CCInt.compare)
    = (l |> List.sort CCInt.compare))
;;

q ~name:"to_iter_sorted"
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    (l |> H.of_list |> H.to_iter_sorted |> Iter.to_list)
    = (l |> List.sort CCInt.compare))
;;

q ~name:"to_string with default sep"
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    (l |> H.of_list |> H.to_string string_of_int)
    = (l |> List.sort CCInt.compare |> List.map string_of_int |> String.concat ","))
;;

q ~name:"to_string with space as sep"
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    (l |> H.of_list |> H.to_string ~sep:" " string_of_int)
    = (l |> List.sort CCInt.compare |> List.map string_of_int |> String.concat " "))
;;

q ~name:"Make_from_compare"
  Q.(list_of_size Gen.small_nat medium_nat)
  (fun l ->
    let module H' = Make_from_compare (CCInt) in
    (l |> H'.of_list |> H'.to_list_sorted)
    = (l |> List.sort CCInt.compare))
