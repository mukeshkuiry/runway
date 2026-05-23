class RunwayMeeting < Formula
  desc "Aviation-themed macOS menu bar app for Google Calendar"
  homepage "https://github.com/mukeshkuiry/runway"
  url "https://github.com/mukeshkuiry/runway/releases/download/v1.0.0/runway-meeting-v1.0.0-darwin-arm64.tar.gz"
  sha256 "a183b4e32b733586a63cb3303db456362a529010884d738067f00d0411dc11d2"
  license "MIT"

  depends_on macos: :ventura

  def install
    bin.install "Runway" => "runway-meeting"
  end

  def post_install
    # The binary self-installs its LaunchAgent on first run,
    # so we just need to launch it once to set everything up.
    # It will start silently in the background on all future logins.
  end

  def caveats
    <<~EOS
      Runway Meeting has been installed!

      To start Runway now (it will auto-start on future logins):
        runway-meeting

      On first launch, you'll be prompted to connect your Google Calendar.

      To stop Runway:
        launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.mukesh.runway.plist

      To uninstall completely:
        brew uninstall runway-meeting
        rm -f ~/Library/LaunchAgents/com.mukesh.runway.plist
        rm -f /tmp/runway.pid
    EOS
  end

  service do
    run opt_bin/"runway-meeting"
    keep_alive false
    process_type :background
    log_path var/"log/runway-meeting.out.log"
    error_log_path var/"log/runway-meeting.err.log"
  end

  test do
    assert_predicate bin/"runway-meeting", :executable?
  end
end
