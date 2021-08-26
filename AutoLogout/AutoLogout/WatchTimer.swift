//
//  WatchTimer.swift
//  AutoLogout
//
//  Created by Adnan Yousaf on 26/08/2021.
//

import Foundation

/// Models a Timer that fires an action when the time runs out.
/// It improves over `NSTimer` in the ability to be be stopped and reset without overhead on the `Run Loop`.
/// It also supports observers that can read on the remainig time on fixed intervals.
public class WatchTimer {
    
    public let duration: TimeDuration
    private let action: () -> Void
    private let queue: DispatchQueue
    
    private(set) var startTime: Date?
    private var endTime: Date? {
        guard let startTime = startTime else { return nil }
        return startTime + duration
    }
    public var remainingTime: TimeDuration? {
        guard let endTime = endTime else { return nil }
        let now = Date()
        return max(endTime.timeDurationSince(now), .seconds(0))
    }
    
    public init(duration: TimeDuration, queue: DispatchQueue = .main, action: @escaping () -> Void) {
        self.duration = duration
        self.startTime = Date()
        self.queue = queue
        self.action = action
        scheduleAction()
    }
    
    private func scheduleAction() {
        guard let remainingTime = remainingTime else { return }
        let closureTarget = ClosureTarget { [weak self] in
            self?.evaluateDeadline()
        }
        Timer.scheduledTimer(timeInterval: remainingTime.in(.seconds), target: closureTarget, selector: #selector(ClosureTarget.execute), userInfo: nil, repeats: false)
        
    }
    
    /// Converts the execution of a Closure to a Target Action
    private class ClosureTarget {
        private let closure: () -> Void
        
        init(closure: @escaping () -> Void) {
            self.closure = closure
        }
        
        @objc func execute() {
            closure()
        }
    }
    
    private func evaluateDeadline() {
        guard let endTime = endTime else { return }
        
        let now = Date()
        if now > endTime {
            action()
            startTime = nil
            return
        }
        scheduleAction()
    }
    
    public func restart() {
        let oldStartTime = self.startTime
        self.startTime = Date()
        if oldStartTime == nil {
            scheduleAction()
        }
    }
    
    public func stop() {
        startTime = nil
    }
    
    // MARK: - Observing Class
    private class ObservingSchedule {
        
        private let startTime = Date()
        private let action: () -> Void
        private let interval: TimeDuration
        private var timer: WatchTimer!
        
        init(interval: TimeDuration, action: @escaping () -> Void) {
            self.interval = interval
            self.action = action
            setupTimer()
        }
        
        func setupTimer() {
            let adjustedInterval = nextObservingTime()
            timer = WatchTimer(duration: adjustedInterval) { [weak self] in
                self?.action()
                self?.setupTimer()
            }
        }
        
        private func nextObservingTime() -> TimeDuration {
            let now = Date()
            let intervalSinceStart = now.timeIntervalSince(startTime)
            let numberOfIntervals = ceil(intervalSinceStart / interval.in(.seconds))
            return TimeDuration(numberOfIntervals * interval.in(.seconds) - intervalSinceStart, .seconds)
        }
    }
    
    private var observerSchedules: [TimerObserver: ObservingSchedule] = [:]
    
    public func add(_ observer: TimerObserver) {
        let schedule = ObservingSchedule(interval: observer.interval) { [weak self] in
            guard let self = self else { return }
            observer.action(self)
        }
        observerSchedules[observer] = schedule
    }
    
    public func remove(_ observer: TimerObserver) {
        observerSchedules.removeValue(forKey: observer)
    }
}

// MARK: TimerObserver
/// The TimeObserver allows the execution an action on fixed intervals during the lifetime of a Timer.
public class TimerObserver: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    public static func == (lhs: TimerObserver, rhs: TimerObserver) -> Bool {
        return lhs === rhs
    }
    
    public let interval: TimeDuration
    let action: (WatchTimer) -> Void
    
    public init(interval: TimeDuration, action: @escaping (WatchTimer) -> Void) {
        self.interval = interval
        self.action = action
    }
}

// MARK:- Time Duration Structure
/// Represents a span of time. Can be converted between miliseconds, seconds, minutes and hours.
public struct TimeDuration: Comparable, Equatable {
    
    private var duration: Double
    
    public struct Unit {
        var conversionFactor: Double
        
        public static let base = seconds
        public static let seconds = Unit(conversionFactor: 1)
        public static let minutes = Unit(conversionFactor: 60)
        public static let hours = Unit(conversionFactor: 60 * 60)
        public static let miliseconds = Unit(conversionFactor: 1 / 1000)
        
    }
    
    public init(_ duration: Double, _ unit: Unit) {
        self.duration = duration * unit.conversionFactor
    }
    
    /// Converts the timespan to the specified unit
    public func `in`(_ unit: Unit) -> Double {
        return duration / unit.conversionFactor
    }
    
    public static func seconds(_ durationInSeconds: Double) -> TimeDuration {
        return TimeDuration(durationInSeconds, .seconds)
    }
    
    public static func miliseconds(_ durationInMiliseconds: Double) -> TimeDuration {
        return TimeDuration(durationInMiliseconds, .miliseconds)
    }
    
    public static func minutes(_ durationInMinutes: Double) -> TimeDuration {
        return TimeDuration(durationInMinutes, .minutes)
    }
    
    public static func hours(_ durationInHours: Double) -> TimeDuration {
        return TimeDuration(durationInHours, .hours)
    }
    
    // MARK: Comparable
    public static func < (lhs: Self, rhs: Self) -> Bool{
        return lhs.duration < rhs.duration
    }
    
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.duration > rhs.duration
    }
    
}


// MARK: - Time operations
public extension DispatchTime {
    
    static func +(lhs: DispatchTime, rhs: TimeDuration) -> DispatchTime {
        let milliseconds = Int(rhs.in(.miliseconds))
        return lhs + DispatchTimeInterval.milliseconds(milliseconds)
    }
    
}

// MARK: - Date Extension
public extension Date {
    static func +(lhs: Date, rhs: TimeDuration) -> Date {
        return lhs.addingTimeInterval(rhs.in(.seconds))
    }
    
    func timeDurationSince(_ date: Date) -> TimeDuration {
        let timeInterval = self.timeIntervalSince(date)
        return .seconds(timeInterval)
    }
}


