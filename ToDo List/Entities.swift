//
//  Entities.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//


import SwiftUI
import CoreData

// MARK: - TaskItem
struct TaskItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var details: String
    var date: Date
    var isCompleted: Bool
}

// MARK: - Дополнительные модели для загрузки из API
struct DummyTodosResponse: Decodable {
    let todos: [DummyTodo]
}

struct DummyTodo: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}

// MARK: - Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ToDoModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Не удалось загрузить хранилище: \(error), \(error.userInfo)")
            }
        }
    }
}

