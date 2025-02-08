//
//  TaskRouter.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//

//
//  TaskRouter.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//

import SwiftUI

/// Router — отвечает за сборку экрана (создаём Interactor, Presenter и т.д.)
struct TaskRouter {
    static func createContentView() -> some View {
        let context = PersistenceController.shared.container.viewContext
        let interactor = TaskInteractor(context: context)
        let presenter = TaskPresenter(interactor: interactor)
        return ContentView(presenter: presenter)
    }
    
    static func createTaskDetailView(task: TaskItem,
                                     updateAction: @escaping (String, String, Date) -> Void,
                                     focusTitle: Bool) -> some View {
        TaskDetailView(
            task: task,
            onUpdate: updateAction,
            focusTitle: focusTitle
        )
    }
}
