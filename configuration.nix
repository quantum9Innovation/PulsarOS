{
  config,
  pkgs,
  inputs,
  pulsar,
  ...
}:

{

  # /*****                                                  /******   /****
  # |*    *|  |*   |  |*       ****     **    *****        |*    |  /*    *
  # |*    *|  |*   |  |*      /*       /* *   |*   |      |*    |  |*
  # |*****/   |*   |  |*       ****   /*   *  |*   /     |*    |   ******
  # |         |*   |  |*           |  ******  *****     |*    |         |
  # |         |*   |  |*       *   |  |*   |  |*  *    |*    |   *     |
  # |          ****    *****    ****  |*   |  |*   *   ******    *****
  #
  #  ==========================================================================

  # Do not edit this configuration file to define what should be installed
  # on your system.
  # Help is available in the configuration.nix(5) man page
  # and in the NixOS manual (accessible by running ‘nixos-help’).
  # This is the default system configuration that ships with PulsarOS.
  # Most of it can be modified from the Pulsar configuration.
  # You can also override it by including other custom configuration files
  # and a custom package list.

  imports = [
    # Include the results of the hardware scan
    pulsar.hardware
  ] ++ pulsar.overrides;

  # Incorporate hotfixes
  nixpkgs.overlays = [
    (self: super: {
      neatvnc = inputs.nixpkgs-upstream.legacyPackages.${pkgs.system}.neatvnc;
    })
  ];

  # Bootloader
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 15;
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
  };

  # Define your hostname
  networking.hostName = pulsar.hostname;

  # Select kernel
  boot.kernelPackages =
    {
      "zen" = pkgs.linuxPackages_zen;
      "latest" = pkgs.linuxPackages_latest;
      "hardened" = pkgs.linuxPackages_latest_hardened; # not recommended
      "libre" = pkgs.linuxPackages_latest-libre;
    }
    .${pulsar.kernel};

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Set time zone automatically
  services.automatic-timezoned.enable = true;

  # Select internationalisation properties
  i18n.defaultLocale = pulsar.locale;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = pulsar.locale;
    LC_IDENTIFICATION = pulsar.locale;
    LC_MEASUREMENT = pulsar.locale;
    LC_MONETARY = pulsar.locale;
    LC_NAME = pulsar.locale;
    LC_NUMERIC = pulsar.locale;
    LC_PAPER = pulsar.locale;
    LC_TELEPHONE = pulsar.locale;
    LC_TIME = pulsar.locale;
  };

  # Faster boot times
  systemd.services = {
    NetworkManager-wait-online.enable = false;
  };

  # Disable the X11 windowing system,
  # since Hyprland uses the more modern Wayland
  services.xserver.enable = false;

  # Enable Wayland support for Electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Compatibility for running binaries not packaged for PulsarOS
  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.icu
      pkgs.glibc
    ];
  };

  # Enable Hyprland
  programs.hyprland.enable = true;

  # Enable SDDM for login and lock management
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
    };
    autoLogin.enable = pulsar.autoLogin;
    autoLogin.user = if pulsar.autoLogin then pulsar.user else null;
  };

  # Enable CUPS to print documents
  services.printing.enable = false;

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # If you want to use JACK applications, set `pulsar.audio.jack` to true
    jack.enable = pulsar.audio.jack;
  };

  # Define a user account
  # Don't forget to set a password with `passwd`
  programs.fish.enable = true;
  users.users.${pulsar.user} = {
    isNormalUser = true;
    description = pulsar.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
  };

  # More user configuration
  nix.optimise.automatic = true;
  nix.settings = {
    allowed-uris = [
      "github:"
      "git+https://github.com/"
      "git+ssh://github.com/"
    ];
    trusted-users = [
      "root"
      pulsar.user
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # Allow unfree packages for proprietary driver support
  nixpkgs.config.allowUnfree = true;

  # Enable CUDA
  nixpkgs.config.cudaSupport = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    with pkgs;
    [
      micro
      curl
      bat
      gnumake
      clang
      gcc
      cachix
      gnupg
      pavucontrol
      inxi
      brightnessctl
      treefmt2
    ]
    ++ (pulsar.systemPackages pkgs);

  # Git is an essential system package
  programs.git.enable = true;

  # Yet another Nix CLI helper
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 14d --keep 12";
    flake = pulsar.flake;
  };

  # Set default editor, among other things
  environment.variables = {
    EDITOR = "micro";
    NIX_AUTO_RUN = 1;
  };

  # Prevent atrocious directories from polluting user home
  environment.etc = {
    "xdg/user-dirs.defaults".text = ''
      	  XDG_DESKTOP_DIR=desk
      	  XDG_DOWNLOAD_DIR=dl
      	  XDG_TEMPLATES_DIR=tmp
      	  XDG_PUBLICSHARE_DIR=pub
      	  XDG_DOCUMENTS_DIR=doc
      	  XDG_MUSIC_DIR=music
      	  XDG_PICTURES_DIR=img
      	  XDG_VIDEOS_DIR=vid
      	  XDG_WALLPAPERS_DIR=wall
        	'';
  };

  # Setup GnuPG
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = pulsar.ssh.enabled;
  };

  # Enable the OpenSSH daemon
  services.openssh.enable = pulsar.ssh.enabled;

  # Ollama
  services.ollama = {
    enable = pulsar.ollama;
    acceleration = "cuda";
  };

  # Hydra
  services.hydra = {
    enable = pulsar.hydra.enabled;
    hydraURL = "http://localhost:${pulsar.hydra.port}";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
    extraConfig = ''
      <git-input>
        timeout = 3600
      </git-input>
    '';
  };

  # Setup Dconf for user configuration of low-level settings
  # Also needed as a dependency for critical system packages
  programs.dconf.enable = true;

  # Enable Docker for hardware virtualization
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = pulsar.graphics.nvidia.enabled;

  # This value determines the NixOS release from which the default settings
  # for stateful data, like file locations and database versions
  # on your system were taken.
  # It‘s perfectly fine and recommended to leave this value at the release
  # version of the first install of this system.
  # Before changing this value, read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = pulsar.stateVersion; # Did you read the comment?

  # Enable OpenGL for optimal graphics performance
  hardware.graphics.enable = pulsar.graphics.opengl;

  # Install and configure appropriate NVIDIA drivers
  # Do not attempt to disable unfree software packages if you enable this
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia =
    if pulsar.graphics.nvidia.enabled then
      {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = true;
        open = false;
        nvidiaSettings = true;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          intelBusId = pulsar.graphics.nvidia.intelBusId;
          nvidiaBusId = pulsar.graphics.nvidia.nvidiaBusId;
        };
      }
    else
      null;

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
      };
    };
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
      (google-fonts.override { fonts = [ "Lora" ]; })
    ];
  };
}
