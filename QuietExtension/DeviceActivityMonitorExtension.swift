import DeviceActivity
import UserNotifications
import ManagedSettings
import FamilyControls

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    let appGroupID = "group.quiettime"
    let userDefaultsKey = "ScreenTimeSelection"
    let decoder = PropertyListDecoder()

    func savedSelection() -> FamilyActivitySelection? {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let data = defaults?.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? decoder.decode(
            FamilyActivitySelection.self,
            from: data
        )
    }

    func scheduleNotification(with title: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title // Using the custom title here
                content.body = "Here is the body text of the notification."
                content.sound = UNNotificationSound.default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // 5 seconds from now
                
                let request = UNNotificationRequest(identifier: "MyNotification", content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            } else {
                print("Permission denied. \(error?.localizedDescription ?? "")")
            }
        }
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Handle the start of the interval.
        print("Interval began")
        scheduleNotification(with: "interval did start")
        let selections = savedSelection()
        store.shield.applicationCategories = .all(except: selections!.applicationTokens)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Handle the end of the interval.
        print("Interval ended")
        scheduleNotification(with: "interval did end")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle the event reaching its threshold.
        print("Threshold reached")
        scheduleNotification(with: "event did reach threshold warning")
        store.shield.applicationCategories = nil
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
        print("Interval will start")
        scheduleNotification(with: "interval will start warning")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
        print("Interval will end")
        scheduleNotification(with: "interval will end warning")
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        // Handle the warning before the event reaches its threshold.
        print("Interval will reach threshold")
        scheduleNotification(with: "event will reach threshold warning")
    }
}
