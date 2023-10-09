{ machine, ... }:
{

  services.nginx = {
    enable = true;
    virtualHosts = {
      ${machine.name} = {
        locations."/" = {
          proxyWebsockets = true;
          recommendedProxySettings = true;
          proxyPass = "http://localhost:3000";
        };

        locations = {

          "~ ^/nix-cache-info" = {
            extraConfig = ''
              proxy_store        on;
              proxy_store_access user:rw group:rw all:r;
              proxy_temp_path    /data/nginx/nix-cache-info/temp;
              root               /data/nginx/nix-cache-info/store;

              proxy_set_header Host "cache.nixos.org";
              proxy_pass https://cache.nixos.org;
            '';
          };

          "~^/nar/.+$" = {
            extraConfig = ''
              proxy_store        on;
              proxy_store_access user:rw group:rw all:r;
              proxy_temp_path    /data/nginx/nar/temp;
              root               /data/nginx/nar/store;

              proxy_set_header Host "cache.nixos.org";
              proxy_pass https://cache.nixos.org;
            '';
          };
        };

      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/nginx/nix-cache-info/temp 0755 nginx nginx"
    "d /data/nginx/nix-cache-info/store 0755 nginx nginx"
    "d /data/nginx/nar/temp 0755 nginx nginx"
    "d /data/nginx/nar/store 0755 nginx nginx"
  ];

  services.permown."/data" = {
    owner = "nginx";
  };

  systemd.services."permown./data" = {
    bindsTo = [ "nginx.service" ];
    after = [ "nginx.service" ];
  };

}
