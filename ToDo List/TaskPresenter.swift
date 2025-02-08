//
//  TaskPresenter.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//



import Foundation
import Combine

// MARK: - Presenter

/// Presenter связывает представление (View) с интерактором (Interactor)
class TaskPresenter: ObservableObject {
    // Ссылка на интерактор
    private let interactor: TaskInteractor
    private var cancellables = Set<AnyCancellable>()
    
    // Представляемые для View свойства
    @Published var searchText: String = ""
    @Published var filteredTasks: [TaskItem] = []
    
    init(interactor: TaskInteractor) {
        self.interactor = interactor
        
        // Прокидываем изменения из интерактора в презентер
        interactor.$searchText
            .receive(on: DispatchQueue.main)
            .assign(to: \.searchText, on: self)
            .store(in: &cancellables)
        
        interactor.$filteredTasks
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredTasks, on: self)
            .store(in: &cancellables)
    }
    
    // Методы, вызываемые из View, просто делегируют вызовы интерактору
    func toggleCompleted(task: TaskItem) {
        interactor.toggleCompleted(task: task)
    }
    
    func delete(task: TaskItem) {
        interactor.delete(task: task)
    }
    
    func add(task: TaskItem) {
        interactor.add(task: task)
    }
    
    func update(task: TaskItem, title: String, details: String, date: Date) {
        interactor.update(task: task, title: title, details: details, date: date)
    }
    
    // При изменении поискового запроса передаем его в интерактор
    func updateSearchText(_ text: String) {
        interactor.searchText = text
    }
}
