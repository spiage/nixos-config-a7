# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, ... }:
let
  kubeMasterIP = "192.168.1.2";
  kubeMasterHostname = "a7.k8s.local";
  # kubeMasterAPIServerPort = 6443;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" "coretemp" ];
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "uas" "usbhid" "sd_mod" ];
  boot.supportedFilesystems = [ "ntfs" "btrfs" "ext4" ];
  boot.kernelModules = [ "kvm-amd" "bfq" "mt7921e" ];
  boot.extraModulePackages = [ ];

  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.bluetooth.enable = true;
  hardware.usb-modeswitch.enable = true;
  hardware.graphics.enable = true;

  networking.networkmanager.enable = true;
  networking.hostName = "a7"; # Define your hostname.
  networking.extraHosts =
    ''
      ${kubeMasterIP} ${kubeMasterHostname}
      136.243.168.226 download.qt.io
    '';
  networking = {
    bridges.br0.interfaces = [ "enp14s0" ];
    useDHCP = false;
    interfaces.enp14s0.useDHCP = false;
    interfaces.br0.useDHCP = true;
  };

  time.timeZone = "Europe/Moscow";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };
  i18n = {
    defaultLocale = "ru_RU.UTF-8";
    supportedLocales = [ "ru_RU.UTF-8/UTF-8" ];
  };

  console = {
    packages = with pkgs; [ terminus_font ];
    font = "ter-v32n";
    keyMap = "ru";
    earlySetup = true;
  };
  
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,ru";
  services.xserver.xkb.options = "grp:win_space_toggle";
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.desktopManager.plasma5.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;
  services.displayManager.sddm.settings.General.DisplayServer = "x11-user";
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "spiage";

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.openFirewall = true;

  services.dbus.packages = [ pkgs.libsForQt5.kpmcore ];
  services.libinput.enable = true;
  services.fwupd.enable = true;

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    nerdfonts
    terminus_font
    terminus_font_ttf
    terminus-nerdfont 
  ];
  
  #scanner
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.sane-airscan ];
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  ###

  services.printing.enable = true;

  # sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.onShutdown = "shutdown";
  virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm;
  virtualisation.libvirtd.qemu.ovmf.packages = [
    (pkgs.OVMF.override {
      secureBoot = true;
      tpmSupport = true;
    }).fd
  ];
  virtualisation.libvirtd.allowedBridges = [ "virbr0" "br0" ];

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = false;
      dockerSocket.enable = false;
      defaultNetwork.settings.dns_enabled = true;
      # declare containers
    };
    oci-containers = {
      ## use podman as default container engine
      backend = "podman";
    };
  };
  virtualisation.docker.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.spiage = {
    isNormalUser = true;
    description = "spiage";
    extraGroups = [ "networkmanager" "wheel" "scanner" "lp" "audio" "incus-admin" "kvm" "libvirtd" "vboxusers" "video" "docker" ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.kdeconnect.enable = true;
  programs.traceroute.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;
  programs.starship.enable = true;
  programs.starship.presets = [ "nerd-font-symbols" ];

  services.rpcbind.enable = true; # needed for NFS
  systemd.mounts = let commonMountOptions = {
    type = "nfs";
    mountConfig = {
      Options = "noatime";
    };
  }; in [
    (commonMountOptions // {
      what = "j4:/vpool";
      where = "/mnt/nfs";
    })
  ];

  systemd.automounts = let commonAutoMountOptions = {
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "600";
    };
  }; in [
    (commonAutoMountOptions // { where = "/mnt/nfs"; })
  ];  

  virtualisation.docker.extraOptions =
    ''--iptables=false --ip-masq=false -b br0'';

  networking.firewall.allowedTCPPorts = [
    2049 #NFSv4
    49152 #libvirt live migration direct connect
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    8080
    3000
    9100 # found input from a7
    10250 # found input from i9
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
  services.k3s = {
    enable = true;
    role = "server";
    token = "Ee1ySKGVulT61yhl2hRDgXVP33OC8R0P"; #tr -dc A-Za-z0-9 </dev/urandom | head -c 32; echo
    clusterInit = true;
    extraFlags = "--write-kubeconfig-mode=644";
  };

  services.openssh.enable = true;
  environment.systemPackages = with pkgs; [
    # dbeaver-bin # Free multi-platform database tool for developers, SQL programmers, database administrators and analysts. Supports all popular databases: MySQL, PostgreSQL, MariaDB, SQLite, Oracle, DB2, SQL Server, Sybase, MS Access, Teradata, Firebird, Derby, etc.
    inputs.last-working-dbeaver-bin.legacyPackages.x86_64-linux.pkgs.dbeaver-bin

    inputs.yandex-browser.packages.x86_64-linux.yandex-browser-stable  
    # yandex-browser

    thunderbird
    birdtray

    firefox

    ansible # Radically simple IT automation
    docker-compose # Docker CLI plugin to define and run multi-container applications with Docker
    filezilla # Graphical FTP, FTPS and SFTP client
    zoom-us # zoom.us video conferencing application
    delve # debugger for the Go programming language
    gdlv # GUI frontend for Delve
    go # The Go Programming language
    ## go env -w GO111MODULE=off (for pass error in VSCode while Ctrl+F5)

    alacritty # A cross-platform, GPU-accelerated terminal emulator
    kitty # A modern, hackable, featureful, OpenGL based terminal emulator
    wezterm # GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust
    #openlens # Kubernetes IDE
    k9s # Kubernetes IDE for console
    kompose
    kubectl
    kubernetes
    kubernetes-helm
    kubernetes-metrics-server

    bridge-utils 
    wget

    inetutils
    micro
    helix
    st
    libreoffice-qt
    vmware-horizon-client

    microsoft-edge
    google-chrome

    telegram-desktop

    mc
    oh-my-git

    git     
    vscode     
    vscode-extensions.ms-toolsai.jupyter     
    vscode-extensions.bbenoist.nix
    vscode-extensions.github.copilot
    vscode-extensions.ms-python.python
    vscode-extensions.hookyqr.beautify
    vscode-extensions.ms-vscode.cpptools
    vscode-extensions.jnoortheen.nix-ide
    vscode-extensions.ms-dotnettools.csharp
    vscode-extensions.kubukoz.nickel-syntax
    vscode-extensions.yzhang.markdown-all-in-one
    vscode-extensions.github.github-vscode-theme
    vscode-extensions.brettm12345.nixfmt-vscode
    vscode-extensions.b4dm4n.vscode-nixpkgs-fmt
    vscode-extensions.mads-hartmann.bash-ide-vscode
    vscode-extensions.davidanson.vscode-markdownlint
    vscode-extensions.ms-vscode-remote.remote-ssh
    vscode-extensions.foam.foam-vscode
    vscode-extensions.bierner.markdown-mermaid
    vscode-extensions.bierner.docs-view
    vscode-extensions.bierner.emojisense
    vscode-extensions.bierner.markdown-checkbox
    vscode-extensions.bierner.markdown-emoji
    vscode-extensions.shd101wyy.markdown-preview-enhanced
    vscode-extensions.tomoki1207.pdf
    vscode-extensions.alefragnani.bookmarks
    vscode-extensions.alefragnani.project-manager
    vscode-extensions.jebbs.plantuml
    vscode-extensions.gruntfuggly.todo-tree
    
    nixd     
    nil
    jq

    partition-manager # inputs.kde2nix.packages.x86_64-linux.partitionmanager
    plasma-workspace-wallpapers #libsForQt5.plasma-workspace-wallpapers #collision with konsole from plasma 5 inputs.kde2nix.packages.x86_64-linux.plasma-workspace-wallpapers
    pavucontrol # libsForQt5.kmix deprecated #marked broken inputs.kde2nix.packages.x86_64-linux.kmix    
    libsForQt5.kcmutils # inputs.kde2nix.packages.x86_64-linux.kcmutils
    remmina # libsForQt5.krdc !vvv remmina is faster vvv!
    skanpage
    ktorrent
    mpv dragon
    kcalc
    skanpage
    #kmines
    #libsForQt5.kpat # inputs.kde2nix.packages.x86_64-linux.kpat
    #discover #fail with plasma 6.0.4
    
    apt
    dpkg
    debootstrap
    
    lm_sensors
    lsof

    ffmpeg #(pkgs.ffmpeg.override { withOptimisations = true; withFullDeps = true; })

    # neofetch
    fastfetch
    btop
    htop

    #python311
    (python3.withPackages(ps: with ps; [ notebook jupyter ])) #!!! waiting for https://github.com/NixOS/nixpkgs/pull/285959
    gcc
    clang
    llvm
    dash

    sqlite
    postgresql

    nix-tree xsel #xclip #pbcopy wl-copy xsel (for 'Y to copy path')
    nvd
    qdirstat
    p7zip
    rar
    fwupd
    nvme-cli
    hw-probe
    inxi
    dmidecode
    clinfo
    glxinfo
    vulkan-tools
    gpu-viewer
    pciutils
    zenstates

    flare
    wesnoth

    qemu_kvm
    virt-manager

    podman-tui
    podman-compose

    wgetpaste
    
    # zed-editor
    anilibria-winmaclinux
    ventoy-full
    
    nut
    libsForQt5.libksysguard
    lm_sensors

    rclone
    masterpdfeditor
    masterpdfeditor4
    terminator

    helvum
    qpwgraph
  ];



  system.stateVersion = "23.05"; # Did you read the comment?

}
