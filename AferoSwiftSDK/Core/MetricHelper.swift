//
//  MetricHelper.swift
//  iTokui
//
//  Created by Martin Arnberg on 4/29/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack


protocol MetricsReportable: class {
    func reportMetrics(metrics: DeviceEventStreamable.Metrics)
}

public class MetricHelper {
    
    static let max_request_timeout_ms: UInt64 = 30_000 // Magic number, same on Android?
    
    weak var metricsReportable: MetricsReportable?
    
    init(metricsReportable: MetricsReportable) {
        self.metricsReportable = metricsReportable
    }
    
    private let coldStartStartTime: UInt64 = mach_absolute_time() // Important: do not add lazy
    private lazy var coldStartEndTime: UInt64 = mach_absolute_time() // Important: do not remove lazy
    
    
    // Only call this once startup is complete
    var coldStartUpTime: UInt64 {
        return MetricHelper.tickToMilliSeconds(coldStartEndTime - coldStartStartTime)
    }
    
    fileprivate var wakeUpStartTime: UInt64?
    
    var wakeUpTime: UInt64? {
        get {
            if let start = wakeUpStartTime {
                return MetricHelper.tickToMilliSeconds(mach_absolute_time() - start)
            }
            return nil
        }
    }
    
    func resetWakeUpTime() {
        wakeUpStartTime = mach_absolute_time()
    }
    
    public static func tickToMilliSeconds(_ ticks: UInt64) -> UInt64 {
        
        var timebase: mach_timebase_info_data_t = mach_timebase_info_data_t()
        mach_timebase_info(&timebase);
        
        let base = UInt64(timebase.numer / timebase.denom)
        
        let nanoSecondsElapsed = ticks * base
        return nanoSecondsElapsed / NSEC_PER_MSEC
    }
    
    fileprivate struct BeginEvent {
        let time: UInt64
        let accountId: String
        let deviceId: String
    }
    
    fileprivate struct EndEvent {
        let time: UInt64
        let success: Bool
        let failureReason: DeviceErrorStatus?
    }
    
    private var beginRequestDeviceMetrics: [Int: BeginEvent] = [:]
    private var endRequestDeviceMetrics: [Int: EndEvent] = [:]
    
    func begin(requestId: Int, accountId: String, deviceId: String, time: UInt64) {
        
        if let orphanedRolloverEvent = beginRequestDeviceMetrics[requestId] {
            self.reportRoundTripError(
                beginEvent: orphanedRolloverEvent,
                time: type(of: self).max_request_timeout_ms
            )
        }
        
        beginRequestDeviceMetrics[requestId] = BeginEvent(
            time: time,
            accountId: accountId,
            deviceId: deviceId
        )
        
        let beginKeys:Set<Int> = Set(beginRequestDeviceMetrics.keys)
        let endKkeys:Set<Int> = Set(endRequestDeviceMetrics.keys)
        let requestIds = beginKeys.intersection(endKkeys)
        
        reportRequestIds(requestIds)
    }
    
    func end(requestId: Int, time: UInt64, success: Bool, failureReason: DeviceErrorStatus?) {
        
        endRequestDeviceMetrics[requestId] = EndEvent(
            time: time,
            success: success,
            failureReason: failureReason
        )
        
        let beginKeys:Set<Int> = Set(beginRequestDeviceMetrics.keys)
        let endKkeys:Set<Int> = Set(endRequestDeviceMetrics.keys)
        let requestIds = beginKeys.intersection(endKkeys)
        
        reportRequestIds(requestIds)
    }
    
    private var metricPayload: [String: [Any]] = [:]
    
    func reportMetrics() {
        metricsReportable?.reportMetrics(metrics: metricPayload)
        metricPayload.removeAll()
    }
    
    func addMetric(_ metric: [String : Any], forMetricType metricType: String) {
        if let _ = metricPayload[metricType] {
            metricPayload[metricType]?.append(metric as Any)
        } else {
            metricPayload[metricType] = [metric as Any]
        }
    }
    
    private func addRoundTripMetric(deviceId: String, millisecondsElapsed: UInt64, success: Bool) {
        
        let metric: [String: Any] = [
            "name": "AttributeChangeRTT",
            "platform": "ios",
            "peripheralId": deviceId,
            "elapsed": NSNumber(value: millisecondsElapsed),
            "success": success,
            ]
        
        addMetric(metric, forMetricType: "peripherals")
    }
    
    private func reportRequestIds(_ requesIds: Set<Int>) {
        
        for requesId in requesIds {
            
            if let beginEvent = beginRequestDeviceMetrics[requesId],
                let endEvent = endRequestDeviceMetrics[requesId] {
                
                let elapsedTicks: UInt64 = endEvent.time >= beginEvent.time ? endEvent.time - beginEvent.time : 0
                
                if endEvent.time < beginEvent.time {
                    // wtf; should never happen
                    DDLogError("End time metric is greater than Start time, beginTime: \(beginEvent.time), endTime: \(endEvent.time)")
                }
                
                addRoundTripMetric(
                    deviceId: beginEvent.deviceId,
                    millisecondsElapsed: MetricHelper.tickToMilliSeconds(elapsedTicks),
                    success: endEvent.success
                )
            }
            
            beginRequestDeviceMetrics.removeValue(forKey: requesId)
            endRequestDeviceMetrics.removeValue(forKey: requesId)
        }
        
        reportMetrics()
        
    }
    
    // NOTE JM: I don't think we need this now. Previoudly, it was called within
    // the deviceCollection to reset state for itself. But that assumes that the
    // MetricHelper is a shared singleton. Now that it's going to be a member of the
    // deviceCollection, it can just tear the helper down on stop, and create
    // a new one on start.
    
    //    func clearRequestMetric() {
    //        for beginKeys in beginRequestDeviceMetrics.keys {
    //            if let beginEvent = beginRequestDeviceMetrics.removeValue(forKey: beginKeys) {
    //
    //                reportRoundTripError(
    //                    deviceId: beginEvent.deviceId,
    //                    time: type(of: self).max_request_timeout_ms
    //                )
    //
    //            }
    //        }
    //        reportMetrics()
    //    }
    
    private func reportRoundTripError(beginEvent: BeginEvent, time: UInt64) {
        reportRoundTripError(
            deviceId: beginEvent.deviceId,
            time: time
        )
    }
    
    private func reportRoundTripError(deviceId: String, time: UInt64) {
        addRoundTripMetric(
            deviceId: deviceId,
            millisecondsElapsed: time,
            success: false
        )
    }
    
}


