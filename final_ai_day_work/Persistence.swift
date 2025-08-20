//
//  Persistence.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/15.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newTask = TaskItem(context: viewContext)
            newTask.id = UUID()
            newTask.title = "示例任务 \(i + 1)"
            newTask.isCompleted = false
            newTask.markAsDeleted = false
            newTask.createdAt = Date()
            newTask.order = Int32(i)
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "final_ai_day_work")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable automatic lightweight migration
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores(completionHandler: { [weak container] (storeDescription, error) in
            if let error = error as NSError? {
                // Check if this is a migration error
                if error.domain == NSCocoaErrorDomain && (error.code == NSPersistentStoreIncompatibleVersionHashError || error.code == NSMigrationError) {
                    // Handle migration error by removing the store and recreating it
                    print("Core Data migration error detected. Attempting to remove old store and recreate.")
                    
                    // Get the store URL
                    if let storeURL = storeDescription.url, let container = container {
                        print("Store URL: \(storeURL)")
                        
                        // Try to remove the existing store
                        do {
                            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
                            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                            print("Successfully recreated persistent store after migration failure.")
                        } catch {
                            print("Failed to recreate persistent store: \(error)")
                            fatalError("Failed to recreate persistent store after migration failure: \(error)")
                        }
                    } else {
                        fatalError("Unresolved migration error \(error), \(error.userInfo)")
                    }
                } else {
                    // Handle other errors
                    /*
                    Typical reasons for an error here include:
                    * The parent directory does not exist, cannot be created, or disallows writing.
                    * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                    * The device is out of space.
                    * The store could not be migrated to the current model version.
                    Check the error message to determine what the actual problem was.
                    */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        })
    }
}
