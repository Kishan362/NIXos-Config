{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # -------------------------
  # Bootloader
  # -------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # -------------------------
  # Networking
  # -------------------------
  networking.hostName = "nixos-MSI";
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" "8.8.8.8" "4.4.4.4"];
  networking.networkmanager.dns = "none";

  # -------------------------
  # Time & Locale
  # -------------------------
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_IN";

  # -------------------------
  # Bluetooth
  # -------------------------
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  # -------------------------
  # Graphics (NVIDIA + Intel PRIME)
  # -------------------------
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.kernel.sysctl = { "vm.max_map_count" = 2147483642; };
  boot.kernelModules = [ "msi-laptop" ];
  boot.kernelParams = [ 
  	"acpi_backlight=native" 
	"usbcore.autosuspend=-1"
	];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # -------------------------
  # Wayland / Hyprland
  # -------------------------
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  }; 
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # -------------------------
  # Display Manager
  # -------------------------
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
  };

  services.xserver.enable = true;

  # -------------------------
  # Audio (PipeWire)
  # -------------------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.pulseaudio.enable = false;

  # -------------------------
  # Input
  # -------------------------
  services.libinput.enable = true;

  # -------------------------
  # Flatpak + Power
  # -------------------------
  services.flatpak.enable = true;
  services.power-profiles-daemon.enable = true;

  # -------------------------
  # XDG Portal
  # -------------------------
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  fileSystems."/mnt/sda" = {
    device = "/dev/sda1";
    fsType = "ntfs"; 
    options = [ "rw" "uid=1000" ];
  };

  # -------------------------
  # Fonts
  # -------------------------
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    font-awesome
    nerd-fonts.symbols-only
  ];

  # -------------------------
  # User
  # -------------------------
  users.users.lki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "adbusers" "gamemode" ];
    packages = with pkgs; [
      tree
      libreoffice-qt
      kitty
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.spectacle
      kdePackages.polkit-kde-agent-1
      networkmanager_dmenu
      wofi
      nwg-dock-hyprland
    ];
  };

  # -------------------------
  # Gaming Specific Config
  # -------------------------
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraPackages = with pkgs; [
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib
      libkrb5
      keyutils
    ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  hardware.xpadneo.enable = true;
  hardware.xone.enable = true;

  # -------------------------
  # System Packages
  # -------------------------
  environment.systemPackages = let
    zen-browser-src = pkgs.fetchFromGitHub {
      owner = "youwen5";
      repo = "zen-browser-flake";
      rev = "master";
      sha256 = "sha256-sCokvdNvl8zIzsnjgG0TN5h3RUI7GJyWW9ErfmEj0rM="; 
    };
    zen-browser-pkg = import zen-browser-src { inherit pkgs; };
  in with pkgs; [
    zen-browser-pkg.default
    
    # Gaming Tools
    mangohud
    goverlay
    protonup-qt
    lutris
    heroic
    bottles
    gamescope

    # Original Packages
    nwg-look
    networkmanager_dmenu 
    vim
    neovim
    usbutils
    wget
    git
    curl
    ripgrep
    fd
    bat
    eza
    btop
    fastfetch
    unzip
    unrar
    p7zip
    file
    jq
    waybar
    rofi
    mako
    libnotify
    swww
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    xdg-utils
    xdg-user-dirs
    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    mpv
    imv
    pavucontrol
    networkmanagerapplet
    blueman
    kitty
    nwg-look
    udiskie
    papirus-icon-theme
    catppuccin-gtk
    glib
  ];

  # -------------------------
  # Nix settings
  # -------------------------
  security.polkit.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  system.stateVersion = "25.11";
}

