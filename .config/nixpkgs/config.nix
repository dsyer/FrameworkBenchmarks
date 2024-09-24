with (import <nixpkgs> { }); {
  packageOverrides = pkgs:
    with pkgs; {
      userPackages = buildEnv {
        # Apply with `nix-env -iA nixpkgs.userPackages`
        name = "user-packages";
        paths = [
          dive
          docker-compose
          docker-credential-gcr
          envsubst
          git
          gitAndTools.hub
          gnumake
          jq
          stow
          yq
          oha
		  wrk
          zip
          unzip
        ];
      };
    };
  allowUnfree = true;
}
