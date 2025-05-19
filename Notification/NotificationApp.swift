// BusyLightMenubarApp.swift
// App menubar macOS qui détecte si Discord ou Beeper sont actifs et allume une lampe Embrava

import SwiftUI
import AppKit
import Foundation

@main
struct BusyLightMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        startMonitoring()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "💡"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.checkActiveApps()
        }
    }

    func checkActiveApps() {
        let runningApps = NSWorkspace.shared.runningApplications
        let frontApp = NSWorkspace.shared.frontmostApplication
        let frontAppName = frontApp?.localizedName?.lowercased() ?? ""

        let isDiscordOrBeeperRunning = runningApps.contains { app in
            guard let name = app.localizedName?.lowercased() else { return false }
            return name.contains("discord") || name.contains("beeper")
        }

        let isUserActivelyUsing = frontAppName.contains("discord") || frontAppName.contains("beeper")

        if isDiscordOrBeeperRunning && isUserActivelyUsing && isMicrophoneInUse() {
            print("[💬] Discord ou Beeper utilisé activement avec micro actif. Allumage de la lampe.")
            self.triggerLamp()
        } else if isDiscordOrBeeperRunning && isUserActivelyUsing {
            print("[🕶] Discord ou Beeper avec micro inactif. Extinction de la lampe.")
            self.turnOffLamp()
        } else {
            print("[🕶] Aucun app ciblé activement utilisée ou micro inactif. Extinction de la lampe.")
            self.turnOffLamp()
        }
    }

    func triggerLamp() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["/Users/ton_nom/Documents/busylight/allume_lampe.py"]
        try? process.run()
    }

    func turnOffLamp() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["/Users/ton_nom/Documents/busylight/eteint_lampe.py"]
        try? process.run()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

import CoreAudio

    func isMicrophoneInUse() -> Bool {
        var deviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)

        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &deviceID)
        if status != noErr {
            return false
        }

        var isRunning: UInt32 = 0
        var propSize = UInt32(MemoryLayout<UInt32>.size)
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)

        let runningStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propSize, &isRunning)
        if runningStatus != noErr {
            return false
        }

        return isRunning != 0
    }

