let 
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
in
pkgs.mkShell {
  buildInputs = [
    pkgs.terraform_1_0_0 

    # keep this line if you use bash
    pkgs.bashInteractive
  ];
  shellHook = ''
    echo "this project will be run with terraform version $(terraform -v)"
  '';
}
