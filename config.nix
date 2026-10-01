{ config, pkgs, inputs, ... }:

{
  # ===========================================================================
  # 1. System Identity, Localization & Nix Maintenance
  # ===========================================================================
  networking.hostName = "msi-63";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true; # Hard-link deduplication to save SSD space
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # ===========================================================================
  # 2. Kernel, Bootloader & Memory Defense
  # ===========================================================================
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # MSI Hardware Module (Fan curves, battery health, EC controls)
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
  boot.kernelModules = [ "msi-ec" ];

  # Memory defense parameters (Safe with Zen & NVIDIA)
  boot.kernelParams = [
    "slab_nomerge"               # Prevents merging kernel caches
    "init_on_alloc=1"            # Zeroes memory pages on allocation
    "init_on_free=1"             # Zeroes memory pages on deallocation
    "page_alloc.shuffle=1"       # Randomizes page allocation order
    "randomize_kstack_offset=on" # Randomizes kernel stack offset per syscall
  ];

  # Limine Bootloader
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Dynamic Linker Shim for Precompiled Binaries (Essential for UV, Python wheels & IDEs)
  programs.nix-ld.enable = true;

  # ===========================================================================
  # 3. Security Subsystem: AppArmor, Sudo & Sysctl
  # ===========================================================================
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  security.sudo.execWheelOnly = true;

  boot.kernel.sysctl = {
    # Disable IPv6 completely across all adapters (Prevents IP leaks)
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
    "net.ipv6.conf.lo.disable_ipv6" = 1;

    # Kernel Information Protection
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.yama.ptrace_scope" = 1;

    # Anti-Spoofing & Network Security
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  # ===========================================================================
  # 4. Encrypted DNS & Stealth Firewall
  # ===========================================================================
  services.resolved = {
    enable = true;
    dnssec = "true";
    dnsovertls = "true";
    domains = [ "~." ];

    # Primary: AdGuard Adblock DNS over TLS (IPv4 + IPv6)
    extraConfig = ''
      DNS=94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com 2a10:50c0::ad1:ff#dns.adguard-dns.com 2a10:50c0::ad2:ff#dns.adguard-dns.com
    '';

    # Fallback: Quad9 Secure DNS over TLS
    fallbackDns = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
      "2620:fe::fe#dns.quad9.net"
    ];
  };

  networking.networkmanager.dns = "systemd-resolved";

  networking.firewall = {
    enable = true;
    allowPing = false; # Stealth mode (Drops ICMP ping requests)
  };

  # ===========================================================================
  # 5. Laptop Power Management (TLP)
  # ===========================================================================
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # Maximum performance when plugged into AC
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      PLATFORM_PROFILE_ON_AC = "performance";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      # Balanced medium performance on Battery
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80;
    };
  };

  # ===========================================================================
  # 6. Bluetooth & Audio (Google Pixel Buds Support)
  # ===========================================================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Exposes battery percentage for Pixel Buds
      };
    };
  };
  services.blueman.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ===========================================================================
  # 7. Display Manager & Desktop Environment
  # ===========================================================================
  # Ly TUI Console Login Manager
  services.displayManager.ly.enable = true;

  # PAM GNOME Keyring Integration
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  # Hyprland Compositor & Screen Locker
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.hyprlock.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Backend services for Nautilus file manager & thumbnails
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # ===========================================================================
  # 8. NVIDIA Hybrid GPU & Hardware Video Acceleration
  # ===========================================================================
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver   # Intel QuickSync hardware acceleration
      nvidia-vaapi-driver  # NVIDIA NVDEC hardware acceleration
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true; # Recommended for Ada Lovelace (RTX 4050)
    nvidiaSettings = true;

    # PRIME Render Offload (Intel iGPU powers screen, RTX 4050 powers heavy apps)
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Provides `nvidia-offload <cmd>`
      };
      # Run `lspci | grep -E "VGA|3D"` to verify bus IDs
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ===========================================================================
  # 9. Fonts Configuration
  # ===========================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # Android / Google Fonts
      roboto
      roboto-mono

      # Universal Language & Emoji Coverage
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      noto-fonts-extra

      # Developer Nerd Fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Roboto" "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # ===========================================================================
  # 10. Default Shell & User Account
  # ===========================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  users.users.lki = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
  };

  # ===========================================================================
  # 11. System Packages & Applications
  # ===========================================================================
  services.hardware.openrgb.enable = true;

  environment.systemPackages = with pkgs; [
    # Privacy & VPN Client
    protonvpn-gui
    protonvpn-cli

    # Web Browsing & Modern Development
    inputs.zen-browser.packages."${pkgs.system}".default
    vscode
    jetbrains.pycharm-community
    python3
    uv
    git
    nano

    # Hyprland Ecosystem
    hyprlock
    hypridle
    swww
    hyprsunset

    # GUI File Manager, Auth Agent & Archive Tools
    nautilus
    file-roller
    p7zip
    unzip
    unrar
    polkit_gnome

    # UI Shell & Launcher
    kitty
    wofi
    waybar
    dunst

    # Clipboard & Screenshot Workflow
    cliphist
    swappy
    wf-recorder
    grim
    slurp
    wl-clipboard

    # Audio & Hardware Controls
    pavucontrol
    brightnessctl
    pamixer
    playerctl

    # System Monitoring & Media
    btop
    mpv
    imv

    # GNOME Keyring Management
    seahorse
    libsecret

    # Hardware & System Utilities
    openrgb
    wget
    curl
    pciutils
    fastfetch
  ];

  system.stateVersion = "26.05";
}