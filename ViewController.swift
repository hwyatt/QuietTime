import UIKit
import FamilyControls
import SwiftUI
import DeviceActivity
import Combine
import ManagedSettings

let store = ManagedSettingsStore()

let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
    intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
    repeats: true,
    warningTime: DateComponents(minute: 15)
)

func description(for selection: FamilyActivitySelection) -> String {
    var result = "Include Entire Category: \(selection.includeEntireCategory ? "Yes" : "No")\n"
    // Assuming you can access the names or descriptions of applications, categories, etc.
    result += "Application Tokens: \(selection.applicationTokens.count)\n"
    result += "Category Tokens: \(selection.categoryTokens.count)\n"
    result += "Web Domain Tokens: \(selection.webDomainTokens.count)"
    return result
}


class ScreenTimeSelectAppsModel: ObservableObject {
    @Published var activitySelection = FamilyActivitySelection()

    init() { }
}

struct ScreenTimeSelectAppsContentView: View {

    @State private var pickerIsPresented = false
    @ObservedObject var model: ScreenTimeSelectAppsModel

    var body: some View {
        VStack {
            Button {
                pickerIsPresented = true
            } label: {
                Text("Select Apps")
            }
            .familyActivityPicker(
                isPresented: $pickerIsPresented,
                selection: $model.activitySelection
            )
            Text("Selected Activities: \(description(for: model.activitySelection))")
            Button {
                store.shield.applicationCategories = nil
                store.shield.webDomainCategories = nil
            } label: {
                Text("Remove Shield")
            }
        }

    }
}

class ViewController: UIViewController {
    
    let model = ScreenTimeSelectAppsModel()
    
    private var cancellables = Set<AnyCancellable>()
        
    // Used to encode codable to UserDefaults
    private let encoder = PropertyListEncoder()

    // Used to decode codable from UserDefaults
    private let decoder = PropertyListDecoder()

    private let userDefaultsKey = "ScreenTimeSelection"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let ac = AuthorizationCenter.shared
        Task {
            do {
                try await ac.requestAuthorization(for: .individual)
            }
            catch {
                print("Error getting auth for Family Controls")
            }
        }
        
//        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//            print("5 seconds have passed!")
//        }
        
        
        let rootView = ScreenTimeSelectAppsContentView(model: model)
        let controller = UIHostingController(rootView: rootView)
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.frame = view.frame
        controller.didMove(toParent: self)
        
        // Set the initial selection
        model.activitySelection = savedSelection() ?? FamilyActivitySelection()
        
        model.$activitySelection.sink { selection in
            self.saveSelection(selection: selection)
        }
        .store(in: &cancellables)
        
        let selection: FamilyActivitySelection = savedSelection()!
        print("Selection is", selection)
        
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: 1)
        )
        
        print("Event is", event)
        print("Event applications", event.applications)
        print("Schedule is", schedule)
        
        let center = DeviceActivityCenter()
        center.stopMonitoring()

        let activity = DeviceActivityName("MyApp.ScreenTime")
        let eventName = DeviceActivityEvent.Name("MyApp.SomeEventName")
        
        print("Starting monitoring")
        
        do {
            try center.startMonitoring(
                activity,
                during: schedule,
                events: [
                    eventName: event
                ]
            )
            print("the final countdown")
        } catch {
            print("Error in do catch block")
        }
    }
    
    let appGroupID = "group.quiettime"
    
    func saveSelection(selection: FamilyActivitySelection) {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(
            try? encoder.encode(selection),
            forKey: userDefaultsKey
        )
    }

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
}
