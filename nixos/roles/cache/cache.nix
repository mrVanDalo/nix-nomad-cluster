{
  services.nix-serve = {
    enable = true;
    openFirewall = true;
    # needed if i want to trust my own build packages and dirivations
    # nix-store --generate-binary-cache-key key-name secret-key-file public-key-file
    # fixme: use a proper secret file here
    secretKeyFile = toString ./secret-key-file;
  };

}
