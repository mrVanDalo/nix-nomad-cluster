{ pkgs, ... }:
{

  services.nix-serve.enable = true;
  # needed if i want to trust my own build packages and dirivations
  # nix-store --generate-binary-cache-key key-name secret-key-file public-key-file
  services.nix-serve.secretKeyFile = toString ./secret-key-file;

  #services.harmonia.enable = true;
  # needed if i want to trust my own build packages and dirivations
  # nix-store --generate-binary-cache-key key-name secret-key-file public-key-file
  #services.harmonia.signKeyPath = toString ./secret-key-file;

  networking.firewall.allowedTCPPorts = [ 443 80 ];

  services.nginx = {
    enable = true;

    #package = pkgs.nginxStable.override {
    #  modules = [ pkgs.nginxModules.zstd ];
    #};

    #recommendedTlsSettings = true;
    #recommendedZstdSettings = true;

    virtualHosts."cache" = {
      #enableACME = true;
      #forceSSL = true;

      # to download the modified image
      locations."/download" = {
        #root = "/srv";
        alias = pkgs.nixos-images.bla;
      };

      locations."/".extraConfig = ''
         proxy_pass http://127.0.0.1:5000;
         proxy_set_header Host $host;
         proxy_redirect http:// https://;
         proxy_http_version 1.1;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection $connection_upgrade;
      '';
    };
  };

}
