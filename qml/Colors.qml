import QtQuick
import Quickshell
import Quickshell.Io

// Dynamic Material Design 3 color palette. Reads matugen-generated colors.json
// from cache and watches for changes, auto-updating all bound UI components.
QtObject {
    id: colors

    // Color file watcher (hot-reloads on wallpaper change)
    property string colorFilePath: Config.cacheDir + "/colors.json"

    property var colorFileView: FileView {
        path: colors.colorFilePath
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: colors._applyColors()
    }

    function _applyColors() {
        var text = colorFileView.text().trim()
        if (!text) return
        try {
            var d = JSON.parse(text)
            colors.primary = d.primary ?? "#ffffff"
            colors.primaryText = d.primaryText ?? "#11111b"
            colors.primaryContainer = d.primaryContainer ?? "#89b4fa"
            colors.primaryContainerText = d.primaryContainerText ?? "#11111b"
            colors.primaryForeground = d.onPrimary ?? "#11111b"
            colors.secondary = d.secondary ?? "#cba6f7"
            colors.secondaryText = d.secondaryText ?? "#11111b"
            colors.secondaryContainer = d.secondaryContainer ?? "#cba6f7"
            colors.secondaryContainerText = d.secondaryContainerText ?? "#11111b"
            colors.tertiary = d.tertiary ?? "#89b4fa"
            colors.tertiaryText = d.tertiaryText ?? "#11111b"
            colors.tertiaryContainer = d.tertiaryContainer ?? "#f5c2e7"
            colors.tertiaryContainerText = d.tertiaryContainerText ?? "#11111b"
            colors.background = d.background ?? "#1e1e2e"
            colors.backgroundText = d.backgroundText ?? "#cdd6f4"
            colors.surface = d.surface ?? "#1e1e2e"
            colors.surfaceText = d.surfaceText ?? "#cdd6f4"
            colors.surfaceVariant = d.surfaceVariant ?? "#313244"
            colors.surfaceVariantText = d.surfaceVariantText ?? "#a6adc8"
            colors.surfaceContainer = d.surfaceContainer ?? "#313244"
            colors.error = d.error ?? "#f38ba8"
            colors.errorText = d.errorText ?? "#11111b"
            colors.errorContainer = d.errorContainer ?? "#f38ba8"
            colors.errorContainerText = d.errorContainerText ?? "#11111b"
            colors.outline = d.outline ?? "#585b70"
            colors.shadow = d.shadow ?? "#11111b"
            colors.inverseSurface = d.inverseSurface ?? "#cdd6f4"
            colors.inverseSurfaceText = d.inverseSurfaceText ?? "#1e1e2e"
            colors.inversePrimary = d.inversePrimary ?? "#89b4fa"
            console.log("Colors: Loaded colors successfully")
        } catch (e) {
            console.log("Colors: Error parsing colors.json:", e)
        }
    }


    // Color properties (Material Design 3 scheme mapped with Catppuccin Mocha fallbacks)
    // Primary
    property color primary: "#ffffff"
    property color primaryText: "#11111b"
    property color primaryContainer: "#89b4fa"
    property color primaryContainerText: "#11111b"
    property color primaryForeground: "#11111b"

    // Secondary
    property color secondary: "#cba6f7"
    property color secondaryText: "#11111b"
    property color secondaryContainer: "#cba6f7"
    property color secondaryContainerText: "#11111b"

    // Tertiary
    property color tertiary: "#89b4fa"
    property color tertiaryText: "#11111b"
    property color tertiaryContainer: "#f5c2e7"
    property color tertiaryContainerText: "#11111b"

    // Background & Surface
    property color background: "#1e1e2e"
    property color backgroundText: "#cdd6f4"
    property color surface: "#1e1e2e"
    property color surfaceText: "#cdd6f4"
    property color surfaceVariant: "#313244"
    property color surfaceVariantText: "#a6adc8"
    property color surfaceContainer: "#313244"

    // Error
    property color error: "#f38ba8"
    property color errorText: "#11111b"
    property color errorContainer: "#f38ba8"
    property color errorContainerText: "#11111b"

    // Utility
    property color outline: "#585b70"
    property color shadow: "#11111b"
    property color inverseSurface: "#cdd6f4"
    property color inverseSurfaceText: "#1e1e2e"
    property color inversePrimary: "#89b4fa"

    // Custom
    property color bgMain: Qt.rgba(20/255, 20/255, 20/255, 0.4)
    property color bgModule: Qt.rgba(45/255, 45/255, 45/255, 0.25)
    property color wsBgActive: Qt.rgba(136/255, 192/255, 208/255, 0.15)
    property color wsTextActive: "#88c0d0"
    property color wsTextInactive: "#d8dee9"
    property color network: "#88c0d0"
    property color clock: "#a3be8c"
    property color audio: "#ebcb8b"
    property color memory: "#77b950"
    property color tempCpu: "#d08770"
    property color tempGpu: "#bf616a"
}