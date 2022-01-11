{ ... }: let
  PORT = 14892;
in {
  config = {
    services.yggdrasil = {
      enable = true;

      persistentKeys = true;
      openMulticastPort = true;
      denyDhcpcdInterfaces = [ "ygg*" ];

      config = {
        Peers = [
          "tcp://ygg.mkg20001.io:80"
          "tls://ygg.mkg20001.io:443"
        ];
        LinkLocalTCPPort = PORT + 1;
        IfName = "ygg0";
        Listen = [
          "tcp://[::]:${toString PORT}"
          "tls://[::]:${toString (PORT + 2)}"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      PORT
      (PORT + 1)
      (PORT + 2)
    ];
  };
}
