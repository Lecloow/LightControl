// BusyLightMenubarApp.swift
// App menubar macOS qui détecte si Discord ou Beeper sont actifs et allume une lampe Embrava

import SwiftUI
import AppKit
import Foundation
import CoreAudio
import AVFoundation


@main
struct BusyLightMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {}
    }
}
enum LampState {
    case off, coding, micro, discord, audio
}
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var isActivated = true // Removed @State
    var currentState: LampState = .off
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        startMonitoring()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: isActivated ? "lightbulb" : "lightbulb.slash", accessibilityDescription: "Lamp")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        if isActivated {
            menu.addItem(NSMenuItem(title: "Turn Off Lamp", action: #selector(switchOff), keyEquivalent: "o"))
        } else {
            menu.addItem(NSMenuItem(title: "Turn On Lamp", action: #selector(switchOn), keyEquivalent: "o"))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
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

        let isCoding = runningApps.contains { app in
            guard let name = app.localizedName?.lowercased() else { return false }
            return name.contains("xcode") || name.contains("pycharm")
        }

        let isUserActivelyUsing = frontAppName.contains("discord") || frontAppName.contains("beeper")
        let isUserActivelyCoding = frontAppName.contains("xcode") || frontAppName.contains("pycharm")

        if isActivated {
            if isCoding && isUserActivelyCoding {
                if currentState != .coding {
                    self.coding()
                    currentState = .coding
                }
            } else if isMicrophoneInUse() {
                if currentState != .micro {
                    self.micro()
                    currentState = .micro
                }
            } else if isAudioPlaying() {
                if currentState != .audio {
                    self.camera()
                    currentState = .audio
                }
            } else if isDiscordOrBeeperRunning && isUserActivelyUsing {
                if currentState != .discord {
                    self.sharingScreen()
                    currentState = .discord
                }
            } else {
                if currentState != .off {
                    self.turnOff()
                    currentState = .off
                }
            }
        }
    }

    func camera() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/Camera.py"]
        try? process.run()
    }
    func micro() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/Micro.py"]
        try? process.run()
    }
    func coding() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/Coding.py"]
        try? process.run()
    }
    func doNotDisturb() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/DoNotDisturb.py"]
        try? process.run()
    }
    func sharingScreen() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/SharingScreen.py"]
        try? process.run()
    }

    func turnOff() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/off.py"]
        try? process.run()
    }

    @objc func switchOff() {
        isActivated = false
        setupMenuBar() // Update icon
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3")
        process.arguments = ["/Users/thomasconchon/Documents/Dev/Xcode/Notification/Notification/Script/off.py"]
        try? process.run()
    }

    @objc func switchOn() {
        isActivated = true
        setupMenuBar() // Update icon
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// ... rest of your helper functions remain unchanged ...

func isAudioPlaying() -> Bool {
    var deviceID = AudioDeviceID(0)
    var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &deviceID)
    if status != noErr {
        return false
    }

    var isRunning: UInt32 = 0
    var propSize = UInt32(MemoryLayout<UInt32>.size)
    address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    let runningStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propSize, &isRunning)
    if runningStatus != noErr {
        return false
    }

    return isRunning != 0
}
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
    
func isScreenBeingShared() -> Bool {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-x", "screensharingd"]

    process.standardOutput = pipe

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        print("Error checking screen sharing: \(error)")
        return false
    }
}

//func isCameraInUse() -> Bool {
//    let process = Process()
//    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
//    process.arguments = ["-x", "VDCAssistant"]
//
//    do {
//        try process.run()
//        process.waitUntilExit()
//        if process.terminationStatus == 0 {
//            return true
//        }
//    } catch {}
//
//    let process2 = Process()
//    process2.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
//    process2.arguments = ["-x", "AppleCameraAssistant"]
//
//    do {
//        try process2.run()
//        process2.waitUntilExit()
//        return process2.terminationStatus == 0
//    } catch {
//        print("Error checking camera usage: \(error)")
//        return false
//    }
//}

//func isCameraInUse() -> Bool {
//    let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external], mediaType: .video, position: .unspecified)
//    let captureSession = AVCaptureSession()
//    
//    for device in discoverySession.devices {
//        print(device.localizedName)
//        
//        if let videoInput = try? AVCaptureDeviceInput(device: device) {
//            let available: String = captureSession.canAddInput(videoInput) ? "true" : "false"
//            print("\tConnected: \(device.isConnected)")
//            print("\tSuspended: \(device.isSuspended)")
//            print("\tAvailable: \(available)")
//            print("\tIs In Use: \(device.isInUseByAnotherApplication)")
//            print()
//        } else {
//            print("\tCould not create input for device: \(device.localizedName)")
//        }
//    }
//    return false
//}


func isCameraInUse() -> Bool {
    let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .external],
        mediaType: .video,
        position: .unspecified
    )
    for device in discoverySession.devices {
        if device.isInUseByAnotherApplication {
            return true
        }
    }
    return false
}
