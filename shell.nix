with import <nixpkgs> {};
mkShell {
  name = "cloud";
  buildInputs = [
      google-cloud-sdk
      terraform
  ];
  shellHook = ''
    echo
    terraform version
    echo
'';
}