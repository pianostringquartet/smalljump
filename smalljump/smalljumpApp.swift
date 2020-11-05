//
//  smalljumpApp.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI
//import CoreData

//// from: https://www.donnywals.com/using-core-data-with-swiftui-2-0-and-xcode-12/
//class PersistenceManager {
//  let persistentContainer: NSPersistentContainer = {
//      let container = NSPersistentContainer(name: "MyApplication")
//      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//          if let error = error as NSError? {
//              fatalError("Unresolved error \(error), \(error.userInfo)")
//          }
//      })
//      return container
//  }()
//
//  init() {
//    let center = NotificationCenter.default
//    let notification = UIApplication.willResignActiveNotification
//
//    center.addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
//      guard let self = self else { return }
//
//      if self.persistentContainer.viewContext.hasChanges {
//        try? self.persistentContainer.viewContext.save()
//      }
//    }
//  }
//}

@main
struct smalljumpApp: App {
//    let persistence = PersistenceManager()
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}


