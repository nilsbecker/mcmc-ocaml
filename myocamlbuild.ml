open Ocamlbuild_plugin


(*let oUnit_dir = Findlib.package_directory "ounit"*)
(*let lacaml_dir = Findlib.package_directory "lacaml"*)

let _ = dispatch begin function
  | After_rules ->
      ocaml_lib "mcmc";
      (*ocaml_lib ~extern:true ~dir:oUnit_dir "oUnit";*)
      (*ocaml_lib ~extern:true ~dir:lacaml_dir "lacaml"*)
  | _ -> ()
end
