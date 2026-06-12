import AlarmKit
import Flutter
import Foundation
import SwiftUI
import UIKit

@available(iOS 26.0, *)
struct WakeSagaAlarmMetadata: AlarmMetadata {
  let wakeSagaAlarmId: String
  let episode: Int
  let quest: String
}

final class WakeSagaAlarmEngine {
  static let shared = WakeSagaAlarmEngine()

  private let channelName = "wakesaga/alarm_engine"
  private let idMapKey = "wakeSaga.alarmKit.idMap.v1"
  private let compatibilityStoreKey = "wakeSaga.compatibilityAlarm.v1"
  private let pendingLaunchKey = "wakeSaga.pendingAlarmLaunch.v1"
  private var channel: FlutterMethodChannel?

  private init() {}

  func attach(to messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel = methodChannel
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(
          FlutterError(
            code: "ALARM_ENGINE_MISSING",
            message: "WakeSaga alarm engine is unavailable.",
            details: nil
          )
        )
        return
      }
      self.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestPermission(result: result)
    case "schedule":
      guard let plan = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "BAD_PLAN",
            message: "Expected alarm plan map.",
            details: nil
          )
        )
        return
      }
      schedule(plan: plan, result: result)
    case "cancel":
      let arguments = call.arguments as? [String: Any]
      cancel(alarmId: arguments?["alarmId"] as? String, result: result)
    case "listScheduled":
      result(listScheduled())
    case "consumeLaunchAlarm":
      result(consumeLaunchAlarm())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermission(result: @escaping FlutterResult) {
    if #available(iOS 26.0, *) {
      Task {
        do {
          let state = try await AlarmManager.shared.requestAuthorization()
          DispatchQueue.main.async {
            result(self.capabilityMap(alarmKitState: state))
          }
        } catch {
          DispatchQueue.main.async {
            result(
              self.capabilityMap(
                alarmKitState: .denied,
                message: "AlarmKit authorization failed: \(error.localizedDescription)"
              )
            )
          }
        }
      }
    } else {
      result(compatibilityCapabilityMap())
    }
  }

  private func schedule(plan: [String: Any], result: @escaping FlutterResult) {
    if #available(iOS 26.0, *) {
      Task {
        do {
          let state = AlarmManager.shared.authorizationState
          guard state == .authorized else {
            DispatchQueue.main.async {
              result(
                FlutterError(
                  code: "ALARMKIT_NOT_AUTHORIZED",
                  message: "AlarmKit authorization is \(state).",
                  details: nil
                )
              )
            }
            return
          }
          let scheduled = try await self.scheduleAlarmKit(plan: plan)
          DispatchQueue.main.async {
            result(scheduled)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "ALARMKIT_SCHEDULE_FAILED",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    } else {
      result(storeCompatibilityAlarm(plan: plan))
    }
  }

  @available(iOS 26.0, *)
  private func scheduleAlarmKit(plan: [String: Any]) async throws -> [String: Any] {
    let dartId = plan["id"] as? String ?? UUID().uuidString
    let nativeId = nativeUUID(for: dartId)
    let hour = plan["hour"] as? Int ?? 6
    let minute = plan["minute"] as? Int ?? 30
    let repeatDays = plan["repeatDays"] as? [Int] ?? []
    let episode = plan["episode"] as? Int ?? 1
    let quest = plan["quest"] as? String ?? "Get Up"
    let mission = plan["mission"] as? String ?? "Wake Quest"
    let title = "EP \(episode): \(mission)"

    let stopButton = AlarmButton(
      text: "Stop",
      textColor: Color.white,
      systemImageName: "stop.fill"
    )
    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: title),
      stopButton: stopButton
    )
    let presentation = AlarmPresentation(alert: alert)
    let metadata = WakeSagaAlarmMetadata(
      wakeSagaAlarmId: dartId,
      episode: episode,
      quest: quest
    )
    let attributes = AlarmAttributes(
      presentation: presentation,
      metadata: metadata,
      tintColor: Color(red: 0.92, green: 0.04, blue: 0.12)
    )
    let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
    let weekdays = repeatDays.compactMap(localeWeekday)
    let repeats: Alarm.Schedule.Relative.Recurrence = weekdays.isEmpty
      ? .never
      : .weekly(weekdays)
    let schedule = Alarm.Schedule.relative(.init(time: time, repeats: repeats))
    let configuration = AlarmManager.AlarmConfiguration.alarm(
      schedule: schedule,
      attributes: attributes
    )

    _ = try await AlarmManager.shared.schedule(
      id: nativeId,
      configuration: configuration
    )

    let scheduledFor = nextFireDate(hour: hour, minute: minute, repeatDays: repeatDays)
    let scheduled = scheduledMap(
      plan: plan,
      scheduledFor: scheduledFor,
      engineMode: "ios-alarmkit"
    )
    storeCompatibilityScheduledMap(scheduled)
    return scheduled
  }

  private func cancel(alarmId: String?, result: FlutterResult) {
    guard let alarmId else {
      result(false)
      return
    }
    if #available(iOS 26.0, *) {
      if let uuid = lookupNativeUUID(for: alarmId) {
        do {
          try AlarmManager.shared.cancel(id: uuid)
        } catch {
          // A missing native alarm should not block Flutter from clearing state.
        }
      }
    }
    removeCompatibilityAlarm(alarmId: alarmId)
    result(true)
  }

  private func listScheduled() -> [[String: Any]] {
    if let saved = UserDefaults.standard.array(forKey: compatibilityStoreKey)
      as? [[String: Any]]
    {
      return saved
    }
    return []
  }

  private func consumeLaunchAlarm() -> [String: Any]? {
    guard
      let launch = UserDefaults.standard.dictionary(forKey: pendingLaunchKey)
        as? [String: Any]
    else {
      return nil
    }
    UserDefaults.standard.removeObject(forKey: pendingLaunchKey)
    return launch
  }

  @available(iOS 26.0, *)
  private func capabilityMap(
    alarmKitState: AlarmManager.AuthorizationState,
    message: String? = nil
  ) -> [String: Any] {
    let alarmKitStatus: String
    switch alarmKitState {
    case .authorized:
      alarmKitStatus = "available"
    case .denied:
      alarmKitStatus = "denied"
    case .notDetermined:
      alarmKitStatus = "unknown"
    @unknown default:
      alarmKitStatus = "unknown"
    }
    return [
      "alarmKit": alarmKitStatus,
      "notifications": "available",
      "exactAlarm": "unavailable",
      "fullScreenIntent": "unavailable",
      "foregroundService": "unavailable",
      "compatibilityMode": alarmKitStatus != "available",
      "message": message ?? "iOS AlarmKit capability checked",
    ]
  }

  private func compatibilityCapabilityMap() -> [String: Any] {
    [
      "alarmKit": "unavailable",
      "notifications": "available",
      "exactAlarm": "unavailable",
      "fullScreenIntent": "unavailable",
      "foregroundService": "unavailable",
      "compatibilityMode": true,
      "message": "AlarmKit requires iOS 26+. WakeSaga is using compatibility mode.",
    ]
  }

  private func storeCompatibilityAlarm(plan: [String: Any]) -> [String: Any] {
    let hour = plan["hour"] as? Int ?? 6
    let minute = plan["minute"] as? Int ?? 30
    let repeatDays = plan["repeatDays"] as? [Int] ?? []
    let scheduled = scheduledMap(
      plan: plan,
      scheduledFor: nextFireDate(hour: hour, minute: minute, repeatDays: repeatDays),
      engineMode: "ios-compatibility"
    )
    storeCompatibilityScheduledMap(scheduled)
    return scheduled
  }

  private func scheduledMap(
    plan: [String: Any],
    scheduledFor: Date,
    engineMode: String
  ) -> [String: Any] {
    [
      "plan": plistSafeDictionary(plan),
      "scheduledFor": isoString(scheduledFor),
      "engineMode": engineMode,
    ]
  }

  private func storeCompatibilityScheduledMap(_ scheduled: [String: Any]) {
    guard
      let plan = scheduled["plan"] as? [String: Any],
      let alarmId = plan["id"] as? String
    else {
      return
    }
    var saved = listScheduled()
    saved.removeAll { item in
      guard
        let existingPlan = item["plan"] as? [String: Any],
        let existingId = existingPlan["id"] as? String
      else {
        return false
      }
      return existingId == alarmId
    }
    saved.append(scheduled)
    UserDefaults.standard.set(saved, forKey: compatibilityStoreKey)
  }

  private func removeCompatibilityAlarm(alarmId: String) {
    var saved = listScheduled()
    saved.removeAll { item in
      guard
        let existingPlan = item["plan"] as? [String: Any],
        let existingId = existingPlan["id"] as? String
      else {
        return false
      }
      return existingId == alarmId
    }
    UserDefaults.standard.set(saved, forKey: compatibilityStoreKey)
  }

  @available(iOS 26.0, *)
  private func localeWeekday(_ dartWeekday: Int) -> Locale.Weekday? {
    switch dartWeekday {
    case 1: return .monday
    case 2: return .tuesday
    case 3: return .wednesday
    case 4: return .thursday
    case 5: return .friday
    case 6: return .saturday
    case 7: return .sunday
    default: return nil
    }
  }

  private func nativeUUID(for dartId: String) -> UUID {
    if let existing = lookupNativeUUID(for: dartId) {
      return existing
    }
    let uuid = UUID()
    var map = UserDefaults.standard.dictionary(forKey: idMapKey) as? [String: String] ?? [:]
    map[dartId] = uuid.uuidString
    UserDefaults.standard.set(map, forKey: idMapKey)
    return uuid
  }

  private func lookupNativeUUID(for dartId: String) -> UUID? {
    let map = UserDefaults.standard.dictionary(forKey: idMapKey) as? [String: String] ?? [:]
    guard let raw = map[dartId] else {
      return nil
    }
    return UUID(uuidString: raw)
  }

  private func nextFireDate(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
    let calendar = Calendar.current
    let now = Date()
    var components = calendar.dateComponents([.year, .month, .day], from: now)
    components.hour = hour
    components.minute = minute
    components.second = 0
    var candidate = calendar.date(from: components) ?? now
    if candidate <= now {
      candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }
    guard !repeatDays.isEmpty else {
      return candidate
    }
    while !repeatDays.contains(weekdayForDart(candidate)) {
      candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }
    return candidate
  }

  private func weekdayForDart(_ date: Date) -> Int {
    let appleWeekday = Calendar.current.component(.weekday, from: date)
    return appleWeekday == 1 ? 7 : appleWeekday - 1
  }

  private func isoString(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private func plistSafeDictionary(_ dictionary: [String: Any]) -> [String: Any] {
    dictionary.reduce(into: [String: Any]()) { result, entry in
      if let safeValue = plistSafeValue(entry.value) {
        result[entry.key] = safeValue
      }
    }
  }

  private func plistSafeArray(_ array: [Any]) -> [Any] {
    array.compactMap(plistSafeValue)
  }

  private func plistSafeValue(_ value: Any) -> Any? {
    if value is NSNull {
      return nil
    }
    if let dictionary = value as? [String: Any] {
      return plistSafeDictionary(dictionary)
    }
    if let array = value as? [Any] {
      return plistSafeArray(array)
    }
    return value
  }
}
