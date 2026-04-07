// Imports
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".."
import "lyrics"
import "dropdowns"


PanelWindow {
  id: bar


  // Required properties from parent
  required property var colors
  required property var clock
  required property bool barVisible
  required property var activePlayer
  required property real cpuUsage
  required property real memUsage
  required property real gpuUsage
  required property real cpuTemp
  required property real gpuTemp
  required property string weatherDesc
  required property string weatherTemp
  required property string weatherCity
  required property var weatherForecast
  required property var barScreen

  WlrLayershell.namespace: "topbar"
  screen: barScreen


  WlrLayershell.keyboardFocus: {
    if (activeDropdown !== "") {
      return WlrKeyboardFocus.Exclusive
    }
    return WlrKeyboardFocus.None
  }

  anchors {
    top: true
    left: true
    right: true
  }

  // Bar dimensions and slide animation
  property real barHeight: 32
  property real topMargin: -1
  property real waveformHeight: 14
  property real slideOffset: barVisible ? 0 : -(barHeight + topMargin)

  // Dropdown state management
  property string activeDropdown: ""

  function closeAllDropdowns() {
    activeDropdown = ""
  }


  FocusScope {
    anchors.fill: parent
    focus: bar.activeDropdown !== ""
    Keys.onEscapePressed: {
      bar.closeAllDropdowns()
    }
  }

  property real animatedBarHeight: barHeight + topMargin + slideOffset

  property int currentWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
  property int totalWorkspaces: 10

  // Dropdown height calculations for stacking
  property real _wifiH: (Config.wifiEnabled && bar.activeDropdown === "wifi") ? wifiDropdown.fullHeight : 0
  property real _calendarH: (Config.calendarEnabled && bar.activeDropdown === "clock") ? calendarDropdown.fullHeight : 0
  property real totalDropdownHeight: _calendarH + _wifiH
  property bool _lyricsPlaying: Config.musicEnabled ? lyricsIsland.musicPlaying : false
  implicitHeight: Math.max(1, animatedBarHeight) + totalDropdownHeight + (_lyricsPlaying ? waveformHeight : 0)
  exclusiveZone: barVisible ? barHeight + topMargin : 0
  color: "transparent"

  Rectangle {
    anchors.fill: barRoot
    color: Qt.rgba(0, 0, 0, 0.67) // Semi-transparent dark bg
    z: -1
  }
  // Workspace focus dispatcher
  Process {
    id: wsDispatcher
    command: ["true"]
    function focusWorkspace(wsId) {
      command = [Config.scriptsDir + "/bash/wm-action", "focus-workspace", wsId.toString()]
      running = true
    }
  }

  mask: Region {
    // Bar area (full width, includes waveform for lyrics)
    width: bar.width
    height: Math.max(1, bar.animatedBarHeight) + (bar._lyricsPlaying ? bar.waveformHeight : 0)

    // Dropdown + right panel area (right-aligned)
    Region {
      x: bar.width - rightPanel.width
      y: Math.max(1, bar.animatedBarHeight)
      width: rightPanel.width
      height: bar.totalDropdownHeight
    }
  }

  Behavior on slideOffset {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }


  // Shape slant angle for parallelogram panels
  property real diagSlant: 28


  // Main bar layout container
  Item {
    id: barRoot
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.topMargin: bar.slideOffset + bar.topMargin
    height: bar.barHeight

  Item {
      id: leftPanel
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: leftContent.implicitWidth + bar.diagSlant + 32

      Canvas {
        id: leftBg
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width - bar.diagSlant, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fillStyle = Qt.rgba(bar.colors.surface.r, bar.colors.surface.g, bar.colors.surface.b, 0.88) 
          ctx.fill()
        }
        Connections {
          target: bar.colors
          function onSurfaceChanged() { leftBg.requestPaint() } 
        }
      }

      Row {
        id: leftContent
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -bar.diagSlant / 2
        spacing: 16

        // Workspaces
        Row {
          id: workspaceRow
          spacing: 12

          Repeater {
            model: bar.totalWorkspaces
            delegate: MouseArea {
              width: 20
              height: 20
              cursorShape: Qt.PointingHandCursor
              
              onClicked: Hyprland.dispatch(`workspace ${index + 1}`)

              Rectangle {
                anchors.centerIn: parent
                width: bar.currentWorkspace === (index + 1) ? 12 : 6
                height: 6
                radius: 3
                color: bar.currentWorkspace === (index + 1) ? bar.colors.primary : bar.colors.tertiary
                
                Behavior on width { NumberAnimation { duration: 200 } }
              }
            }
          }
        }

        // Vertical Separator
        Rectangle {
          width: 1
          height: 14
          color: bar.colors.tertiary
          opacity: 0.3
          anchors.verticalCenter: parent.verticalCenter
        }

        // Quick Actions
        Row {
          id: quickActionsRow
          spacing: 12
          anchors.verticalCenter: parent.verticalCenter

          // Processes
          Process { id: discordProcess; command: ["discord"] }
          Process { id: explorerProcess; command: ["kitty", "yazi"] }
          Process { id: firefoxProcess; command: ["firefox"] }
          Process { id: vscodeProcess; command: ["code"] }
          Process { id: rebootWindowsProcess; command: ["sh", "-c", "grub-reboot 'Windows Boot Manager' && reboot"] }

          // Discord Button
          Text {
            text: ""
            font.pixelSize: 14
            font.family: Style.fontFamilyNerdIcons
            color: discordMouse.containsMouse ? bar.colors.primary : bar.colors.tertiary
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
              id: discordMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: discordProcess.running = true
            }
          }

          // Explorer Button
          Text {
            text: "󰉋"
            font.pixelSize: 14
            font.family: Style.fontFamilyNerdIcons
            color: explorerMouse.containsMouse ? bar.colors.primary : bar.colors.tertiary
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
              id: explorerMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: explorerProcess.running = true
            }
          }

          // Firefox Button
          Text {
            text: ""
            font.pixelSize: 14
            font.family: Style.fontFamilyNerdIcons
            color: firefoxMouse.containsMouse ? bar.colors.primary : bar.colors.tertiary
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
              id: firefoxMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: firefoxProcess.running = true
            }
          }

          // VS Code Button
          Text {
            text: "󰨞"
            font.pixelSize: 14
            font.family: Style.fontFamilyNerdIcons
            color: vscodeMouse.containsMouse ? bar.colors.primary : bar.colors.tertiary
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
              id: vscodeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: vscodeProcess.running = true
            }
          }

          // Windows Restart Button (Last)
          Text {
            text: ""
            font.pixelSize: 14
            font.family: Style.fontFamilyNerdIcons
            color: windowsMouse.containsMouse ? bar.colors.primary : bar.colors.tertiary
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
              id: windowsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: rebootWindowsProcess.running = true
            }
          }
        }
      }
    }


    // Center panel (lyrics island)
    LyricsIsland {
      id: lyricsIsland
      visible: Config.musicEnabled && (!Config.musicAutohide || (bar.activePlayer && bar.activePlayer.isPlaying))
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      colors: bar.colors
      activePlayer: bar.activePlayer
      diagSlant: bar.diagSlant
      barHeight: bar.barHeight
      waveformHeight: bar.waveformHeight
    }

    // Right panel (wifi, volume, clock, temps)
    Item {
      id: rightPanel
      z: 1
      anchors.right: parent.right
      anchors.top: parent.top        // Locks to barRoot
      anchors.bottom: parent.bottom  // Locks to barRoot
      width: rightContent.implicitWidth + bar.diagSlant + 24

      Canvas {
        id: rightBg
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)

          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width, height)
          ctx.lineTo(0 + bar.diagSlant, height)
          ctx.closePath()
          ctx.fillStyle = Qt.rgba(bar.colors.surface.r, bar.colors.surface.g, bar.colors.surface.b, 0.88)
          ctx.fill()
        }
        Connections {
          target: bar.colors
          function onSurfaceChanged() { rightBg.requestPaint() }
          function onPrimaryChanged() { rightBg.requestPaint() }
        }
      }

      Row {
        id: rightContent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: bar.diagSlant / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        // Unified Network Widget (Ethernet & WiFi)
        Item {
          id: networkWidget
          implicitWidth: networkRow.implicitWidth
          implicitHeight: networkRow.implicitHeight
          visible: true

          // Properties exposed for the dropdown
          property string networkName: networkInfo.name
          property int networkSignal: networkInfo.signalStrength

          Row {
            id: networkRow
            spacing: 4
            Text {
              text: {
                if (networkInfo.type === "ethernet") return "󰈀 "
                if (networkInfo.type === "wifi") {
                  let s = networkInfo.signalStrength
                  if (s < 25) return "󰤟 "
                  if (s < 50) return "󰤢 "
                  if (s < 75) return "󰤥 "
                  return "󰤨 "
                }
                return "󰖪 " 
              }
              font.pixelSize: 14
              font.family: Style.fontFamilyNerdIcons
              color: bar.colors.network
            }
            Text {
              text: networkInfo.name !== "" ? networkInfo.name : "Disconnected"
              font.pixelSize: 12
              font.weight: Font.Medium
              font.family: Style.fontFamily
              color: bar.colors.network
            }
          }

          QtObject {
            id: networkInfo
            property string type: "disconnected"
            property string name: ""
            property int signalStrength: 0
            Component.onCompleted: networkPollTimer.start()
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            // Toggle the dropdown when clicked
            onClicked: bar.activeDropdown = bar.activeDropdown === "wifi" ? "" : "wifi"
          }

          Process {
            id: networkProcess
            command: ["sh", "-c", "nmcli -t -f TYPE,CONNECTION,DEVICE dev | grep -m1 -E '^(ethernet|wifi):' || echo 'disconnected'"]
            onExited: {
              if (networkInfo.type === "wifi") wifiSignalProcess.running = true
              else networkPollTimer.start()
            }
            stdout: SplitParser {
              onRead: data => {
                let parts = data.trim().split(":")
                if (parts[0] === "disconnected" || parts.length < 2) {
                  networkInfo.type = "disconnected"
                  networkInfo.name = ""
                } else {
                  networkInfo.type = parts[0]
                  networkInfo.name = parts[1]
                }
              }
            }
          }

          Process {
            id: wifiSignalProcess
            command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\\*' | cut -d: -f2"]
            onExited: networkPollTimer.start()
            stdout: SplitParser {
              onRead: data => {
                let signal = parseInt(data.trim())
                if (!isNaN(signal)) networkInfo.signalStrength = signal
              }
            }
          }

          Timer {
            id: networkPollTimer
            interval: 5000 
            onTriggered: networkProcess.running = true
          }
        }

        // Stats widgets (CPU, GPU, memory usage and temperatures) - click to open system monitor
        Item {
          id: statsWidget
          visible: Config.statsEnabled
          implicitWidth: statsRow.implicitWidth
          implicitHeight: statsRow.implicitHeight
          Process {
            id: monitorToggleProcess
            command: ["kitty", "btop"]
          }
          Row {
            id: statsRow
            spacing: 12
            Text { text: "  " + Math.round(bar.cpuTemp) + "°C"; color: bar.colors.tempCpu; font.family: Style.fontFamilyNerdIcons; font.pixelSize: Style.fontBodyLarge }
            Text { text: "󰢮  " + Math.round(bar.gpuTemp) + "°C"; color: bar.colors.tempGpu; font.family: Style.fontFamilyNerdIcons; font.pixelSize: Style.fontBodyLarge }
            Text { text: "   " + Math.round(bar.memUsage) + "%"; color: bar.colors.memory; font.family: Style.fontFamilyNerdIcons; font.pixelSize: Style.fontBodyLarge }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              // Safely execute the system monitor process
              monitorToggleProcess.running = true
            }
          }
        }
        // Volume widget with level icon
        Item {
          id: volumeWidget
          visible: Config.volumeEnabled
          implicitWidth: volumeRow.implicitWidth
          implicitHeight: volumeRow.implicitHeight

          Process {
            id: audioToggleProcess
            command: ["/home/haziel/.config/waybar/toggle-audio.sh", "toggle"]
          }

          Row {
            id: volumeRow
            spacing: 4
            Text {
              text: {
                let sink = Pipewire.defaultAudioSink
                if (!sink || !sink.audio) return "󰖁"

                let vol = sink.audio.volume
                let isMuted = sink.audio.muted
                let desc = (sink.description || "").toLowerCase()
                let name = (sink.name || "").toLowerCase()

                if (isMuted || vol === 0) return "󰝟" 

                if (desc.includes("headphone") || desc.includes("headset") || name.includes("bluez") || desc.includes("analog")) return "󰋋" 
                if (desc.includes("hdmi") || desc.includes("tv")) return "󰡁" 

                if (vol < 0.33) return "󰕿"
                if (vol < 0.66) return "󰖀"
                return "󰕾"
              }
              font.pixelSize: 14
              font.family: Style.fontFamilyNerdIcons
              color: bar.colors.audio
              width: 16
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              text: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"
              font.pixelSize: 12
              font.weight: Font.Medium
              font.family: Style.fontFamily
              color: bar.colors.audio
              width: Math.max(implicitWidth, 28)
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            
            // Execute process safely
            onClicked: audioToggleProcess.running = true
            
            onWheel: (wheel) => {
              let sink = Pipewire.defaultAudioSink
              if (!sink || !sink.audio) return
              
              let step = 0.05 
              let currentVol = sink.audio.volume
              
              if (wheel.angleDelta.y > 0) sink.audio.volume = Math.min(1.0, currentVol + step)
              if (wheel.angleDelta.y < 0) sink.audio.volume = Math.max(0.0, currentVol - step)
            }
          }
        }


        // Clock widget
        Item {
          id: clockWidget
          visible: Config.calendarEnabled
          implicitWidth: clockRow.implicitWidth
          implicitHeight: clockRow.implicitHeight

          Row {
            id: clockRow
            spacing: 0
            Text {
              text: " "
              font.pixelSize: 13
              font.weight: Font.DemiBold
              font.family: Style.fontFamily
              color: bar.colors.clock
            }
            Text {
              text: Qt.formatTime(bar.clock.date, "HH")
              font.pixelSize: 13
              font.weight: Font.DemiBold
              font.family: Style.fontFamily
              color: bar.colors.clock
            }
            Text {
              text: ":"
              font.pixelSize: 13
              font.weight: Font.DemiBold
              font.family: Style.fontFamily
              color: bar.colors.clock
            }
            Text {
              text: Qt.formatTime(bar.clock.date, "mm")
              font.pixelSize: 13
              font.weight: Font.DemiBold
              font.family: Style.fontFamily
              color: bar.colors.clock
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              bar.activeDropdown = bar.activeDropdown === "clock" ? "" : "clock"
            }
          }
        }

      }
    }
  }

  // Dropdown panel instances (stacked below the bar)
  WiFiDropdown {
    id: wifiDropdown
    anchors.right: parent.right
    y: bar.slideOffset + bar.topMargin
    width: rightPanel.width
    colors: bar.colors
    active: Config.wifiEnabled && bar.activeDropdown === "wifi"
    
    // Bind to the new network properties
    wifiSsid: networkWidget.networkName
    wifiSignalStrength: networkWidget.networkSignal
  }

  CalendarDropdown {
    id: calendarDropdown
    anchors.right: parent.right
    y: bar.slideOffset + bar.topMargin + bar._wifiH
    width: rightPanel.width
    colors: bar.colors
    active: Config.calendarEnabled && bar.activeDropdown === "clock"
    clock: bar.clock
  }
}