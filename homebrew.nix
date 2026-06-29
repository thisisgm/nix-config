{ ... }:
{
  # GUI apps + Mac App Store apps. nix-darwin drives Homebrew/mas; the *list* is
  # declarative here, brew/mas do the install. Requires Homebrew already installed
  # and (for masApps) being signed into the App Store. See README.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Declarative pruning: removes any cask/formula not listed below (verified
      # migration complete + brew already retired, so safe to enforce now).
      cleanup = "zap";
    };

    casks = [
      "google-chrome"
      "whatsapp"
      "discord"
      "notion"
      "slack"
      "claude"
      "proton-mail"
      "ghostty"
      "tailscale-app"   # GUI app cask (`tailscale` is now the CLI formula)
      "adguard"
      "cyberduck"
      "keka"
      "1password"
      "1password-cli"
    ];

    # name = numeric App Store ID (verified via mdls). Curated subset only.
    masApps = {
      "Infuse" = 1136220934;
      "Amperfy" = 1530145038;
      "Parcel" = 375589283;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
    };
  };
}
