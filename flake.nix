{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    arduino-nix.url = "github:bouk/arduino-nix";
    arduino-index = {
      url = "github:bouk/arduino-indexes";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      arduino-nix,
      arduino-index,
      ...
    }@attrs:
    let
      overlays = [
        (arduino-nix.overlay)
        (arduino-nix.mkArduinoPackageOverlay (arduino-index + "/index/package_index.json"))
        (arduino-nix.mkArduinoPackageOverlay (arduino-index + "/index/package_rp2040_index.json"))
        (arduino-nix.mkArduinoLibraryOverlay (arduino-index + "/index/library_index.json"))
      ];
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system overlays;

          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "13.0";
          toolsVersion = "26.1.1";
          platformVersions = [
            "34"
            "33"
          ];
          buildToolsVersions = [ "34.0.0" ];
          includeEmulator = true;
        };

        androidSdk = androidComposition.androidsdk;
      in

      rec {
        packages.arduino-cli = pkgs.wrapArduinoCLI {
          libraries = with pkgs.arduinoLibraries; [
            (arduino-nix.latestVersion ADS1X15)
            (arduino-nix.latestVersion Ethernet_Generic)
            (arduino-nix.latestVersion SCL3300)
            (arduino-nix.latestVersion TMCStepper)
            (arduino-nix.latestVersion pkgs.arduinoLibraries."Adafruit PWM Servo Driver Library")
          ];

          packages = with pkgs.arduinoPackages; [
            platforms.arduino.avr."1.6.23"
            platforms.rp2040.rp2040."2.3.3"
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            self.packages.${system}.arduino-cli
            pkgs.picocom
            pkgs.clang-tools
            pkgs.arduino-ide

            pkgs.flutter
            pkgs.androidsdk
            pkgs.android-studio
          ];
          shellHook = ''
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export JAVA_HOME="${pkgs.jdk17}"
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"

            export NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE=1
            export NIXPKGS_ALLOW_UNFREE=1
            export PKG_CONFIG_PATH="${pkgs.gtk3.dev}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:${pkgs.pango.dev}/lib/pkgconfig:${pkgs.cairo.dev}/lib/pkgconfig:${pkgs.gdk-pixbuf.dev}/lib/pkgconfig:${pkgs.atk.dev}/lib/pkgconfig"

          '';
        };
      }
    ));
}
