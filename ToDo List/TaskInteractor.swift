//
//  TaskInteractor.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//

import Foundation
import CoreData
import Combine

// MARK: - Interactor

/// Этот класс содержит бизнес-логику для работы с задачами. (Ранее – TaskViewModel)
class TaskInteractor: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var filteredTasks: [TaskItem] = []
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        loadTasksFromCoreData()
        // Если в хранилище нет задач – загружаем их с API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.tasks.isEmpty {
                self.loadTasksFromAPI()
            }
        }
        
        // Фильтрация по поисковому запросу с задержкой
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] text in
                self?.filterTasks(with: text)
            }
            .store(in: &cancellables)
    }
    
    // Загрузка задач из Core Data
    private func loadTasksFromCoreData() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        context.perform {
            do {
                let entities = try self.context.fetch(request)
                let loadedTasks = entities.map { entity in
                    TaskItem(
                        id: entity.id ?? UUID(),
                        title: entity.title ?? "",
                        details: entity.details ?? "",
                        date: entity.date ?? Date(),
                        isCompleted: entity.isCompleted
                    )
                }
                DispatchQueue.main.async {
                    self.tasks = loadedTasks
                    self.filterTasks(with: self.searchText)
                }
            } catch {
                print("Ошибка загрузки задач из Core Data: \(error)")
            }
        }
    }
    
    // Фильтрация задач
    private func filterTasks(with search: String) {
        let lowercased = search.lowercased()
        let filtered = search.isEmpty ? tasks : tasks.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.details.lowercased().contains(lowercased)
        }
        DispatchQueue.main.async {
            self.filteredTasks = filtered
        }
    }
    
    // Загрузка задач с JSON API и сохранение в Core Data
    func loadTasksFromAPI() {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            print("Неверный URL")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки задач с API: \(error)")
                return
            }
            guard let data = data else {
                print("Нет данных от API")
                return
            }
            do {
                let decoder = JSONDecoder()
                let dummyResponse = try decoder.decode(DummyTodosResponse.self, from: data)
                self.context.perform {
                    for dummyTodo in dummyResponse.todos {
                        let newEntity = TaskEntity(context: self.context)
                        newEntity.id = UUID()
                        newEntity.title = dummyTodo.todo
                        newEntity.details = "UserId: \(dummyTodo.userId)"
                        newEntity.date = Date() // Так как дата отсутствует в API
                        newEntity.isCompleted = dummyTodo.completed
                    }
                    do {
                        try self.context.save()
                        self.loadTasksFromCoreData()
                    } catch {
                        print("Ошибка сохранения задач из API: \(error)")
                    }
                }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
            }
        }.resume()
    }
    
    // Добавление новой задачи
    func add(task: TaskItem) {
        context.perform {
            let newEntity = TaskEntity(context: self.context)
            newEntity.id = task.id
            newEntity.title = task.title
            newEntity.details = task.details
            newEntity.date = task.date
            newEntity.isCompleted = task.isCompleted
            do {
                try self.context.save()
                self.loadTasksFromCoreData()
            } catch {
                print("Ошибка добавления задачи: \(error)")
            }
        }
    }
    
    // Обновление задачи
    func update(task: TaskItem, title: String, details: String, date: Date) {
        context.perform {
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            do {
                if let entity = try self.context.fetch(request).first {
                    entity.title = title
                    entity.details = details
                    entity.date = date
                    try self.context.save()
                    self.loadTasksFromCoreData()
                }
            } catch {
                print("Ошибка обновления задачи: \(error)")
            }
        }
    }
    
    // Удаление задачи
    func delete(task: TaskItem) {
        context.perform {
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            do {
                if let entity = try self.context.fetch(request).first {
                    self.context.delete(entity)
                    try self.context.save()
                    self.loadTasksFromCoreData()
                }
            } catch {
                print("Ошибка удаления задачи: \(error)")
            }
        }
    }
    
    // Переключение статуса выполнения задачи
    func toggleCompleted(task: TaskItem) {
        context.perform {
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            do {
                if let entity = try self.context.fetch(request).first {
                    entity.isCompleted.toggle()
                    try self.context.save()
                    self.loadTasksFromCoreData()
                }
            } catch {
                print("Ошибка переключения статуса задачи: \(error)")
            }
        }
    }
}
