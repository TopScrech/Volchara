import Foundation
import IOKit
import IOKit.hid

private let spuAccelUsagePage = 0xFF00
private let spuAccelUsage = 3
private let imuReportLength = 22
private let imuDataOffset = 6
private let imuScale = 65536.0
private let reportBufferLength = 4096

private let sensorReportCallback: IOHIDReportCallback = { context, _, _, _, _, report, reportLength in
    guard reportLength == imuReportLength else { return }
    guard let context else { return }

    let service = Unmanaged<SPUSensorService>.fromOpaque(context).takeUnretainedValue()
    let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))

    MainActor.assumeIsolated {
        service.handleReport(bytes)
    }
}

@MainActor
final class SPUSensorService {
    typealias SampleHandler = (SensorSample) -> Void

    private struct RegisteredDevice {
        let device: IOHIDDevice
        let buffer: UnsafeMutablePointer<UInt8>
    }

    private var manager: IOHIDManager?
    private var registeredDevices: [RegisteredDevice] = []
    private var sampleHandler: SampleHandler?
    private var decimationCounter = 0

    func start(onSample: @escaping SampleHandler) -> Bool {
        if isRunning {
            sampleHandler = onSample
            return true
        }

        wakeSPUDrivers()

        let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(hidManager, nil)
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))

        guard let devices = IOHIDManagerCopyDevices(hidManager) as? Set<IOHIDDevice> else {
            return false
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        var entries: [RegisteredDevice] = []

        for device in devices {
            guard isSPUAccelerometer(device) else { continue }

            let openResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
            guard openResult == kIOReturnSuccess else { continue }

            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: reportBufferLength)
            buffer.initialize(repeating: 0, count: reportBufferLength)

            IOHIDDeviceRegisterInputReportCallback(
                device,
                buffer,
                reportBufferLength,
                sensorReportCallback,
                context
            )
            IOHIDDeviceScheduleWithRunLoop(
                device,
                CFRunLoopGetMain(),
                CFRunLoopMode.defaultMode.rawValue
            )

            entries.append(RegisteredDevice(device: device, buffer: buffer))
        }

        guard !entries.isEmpty else {
            IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
            return false
        }

        manager = hidManager
        registeredDevices = entries
        sampleHandler = onSample
        decimationCounter = 0
        return true
    }

    func stop() {
        for entry in registeredDevices {
            IOHIDDeviceUnscheduleFromRunLoop(
                entry.device,
                CFRunLoopGetMain(),
                CFRunLoopMode.defaultMode.rawValue
            )
            IOHIDDeviceClose(entry.device, IOOptionBits(kIOHIDOptionsTypeNone))
            entry.buffer.deinitialize(count: reportBufferLength)
            entry.buffer.deallocate()
        }

        registeredDevices.removeAll()

        if let manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        self.manager = nil
        sampleHandler = nil
        decimationCounter = 0
    }

    var isRunning: Bool {
        !registeredDevices.isEmpty
    }

    fileprivate func handleReport(_ report: [UInt8]) {
        guard report.count == imuReportLength else { return }

        decimationCounter += 1
        if decimationCounter < 8 {
            return
        }
        decimationCounter = 0

        let x = readInt32(from: report, offset: imuDataOffset)
        let y = readInt32(from: report, offset: imuDataOffset + 4)
        let z = readInt32(from: report, offset: imuDataOffset + 8)

        let sample = SensorSample(
            x: Double(x) / imuScale,
            y: Double(y) / imuScale,
            z: Double(z) / imuScale
        )

        sampleHandler?(sample)
    }

    private func readInt32(from bytes: [UInt8], offset: Int) -> Int32 {
        Int32(bitPattern: UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24))
    }

    private func isSPUAccelerometer(_ device: IOHIDDevice) -> Bool {
        guard let usagePage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? NSNumber,
              let usage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsageKey as CFString) as? NSNumber,
              let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String
        else {
            return false
        }

        return usagePage.intValue == spuAccelUsagePage
            && usage.intValue == spuAccelUsage
            && transport == "SPU"
    }

    private func wakeSPUDrivers() {
        let matching = IOServiceMatching("AppleSPUHIDDriver")
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

        guard result == KERN_SUCCESS else { return }

        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }

            IORegistryEntrySetCFProperty(service, "SensorPropertyReportingState" as CFString, 1 as CFNumber)
            IORegistryEntrySetCFProperty(service, "SensorPropertyPowerState" as CFString, 1 as CFNumber)
            IORegistryEntrySetCFProperty(service, "ReportInterval" as CFString, 1000 as CFNumber)

            IOObjectRelease(service)
        }

        IOObjectRelease(iterator)
    }
}
