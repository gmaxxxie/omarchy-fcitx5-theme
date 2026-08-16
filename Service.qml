import QtQuick
import Quickshell
import Quickshell.Io

// Keeps the fcitx5 candidate-box theme in sync with the current Omarchy theme.
//
// `omarchy theme set` rewrites ~/.local/state/omarchy/current/theme/colors.toml;
// watching that file lets this service react live, without polling, and without
// touching the theme-set hook (the hook remains an optional fallback for
// headless theme sets where the shell is not watching).
Item {
  id: root
  visible: false

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string themeColorsPath: home + "/.local/state/omarchy/current/theme/colors.toml"
  readonly property string generator: home + "/.config/omarchy/plugins/gmaxxxie.fcitx5-theme/fcitx5-classicui-theme.sh"

  // Watch the current theme's colors file. The generator is idempotent
  // (skips the fcitx5 restart when nothing changed), so firing on every
  // theme-set rewrite is cheap.
  FileView {
    id: themeWatcher
    path: root.themeColorsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.sync()
    onLoadFailed: {} // state not present yet; watcher re-fires when it appears
  }

  // Fallback: ensure a sync shortly after shell start even if the state file
  // existed before the shell came up and no change event is guaranteed.
  Timer {
    interval: 5000
    running: true
    repeat: false
    onTriggered: root.sync()
  }

  Process {
    id: syncProc
    command: ["/bin/bash", root.generator, "current", "--quiet"]
    onFailed: console.warn("fcitx5-theme", "sync failed")
  }

  function sync() {
    if (syncProc.running) return
    syncProc.running = true
  }
}
