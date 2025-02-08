//
//  ContentView.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//

import SwiftUI
import Speech
import AVFoundation

// MARK: - ContentView
struct ContentView: View {
    // Presenter приходит извне
    @StateObject var presenter: TaskPresenter
    
    // Для перехода на детальный экран
    @State private var selectedTaskForDetail: TaskItem? = nil
    @State private var isDetailActive = false
    @State private var shouldFocusTitle = false
    
    // Голосовой ввод
    @State private var isRecording = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private let audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerView
                    List {
                        ForEach(presenter.filteredTasks) { task in
                            TaskRow(task: task) {
                                presenter.toggleCompleted(task: task)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTaskForDetail = task
                                shouldFocusTitle = false
                                isDetailActive = true
                            }
                            .contextMenu {
                                Button {
                                    selectedTaskForDetail = task
                                    shouldFocusTitle = true
                                    isDetailActive = true
                                } label: {
                                    Label("Редактировать", systemImage: "square.and.pencil")
                                }
                                Button {
                                    shareTask(task: task)
                                } label: {
                                    Label("Поделиться", systemImage: "square.and.arrow.up")
                                }
                                Button(role: .destructive) {
                                    presenter.delete(task: task)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.black)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, 8)
                    
                    bottomBarView(tasksCount: presenter.filteredTasks.count)
                }
                
                // Переход к детальному экрану через Router
                NavigationLink(
                    destination: Group {
                        if let task = selectedTaskForDetail {
                            TaskRouter.createTaskDetailView(
                                task: task,
                                updateAction: { title, details, date in
                                    presenter.update(task: task, title: title, details: details, date: date)
                                },
                                focusTitle: shouldFocusTitle
                            )
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $isDetailActive,
                    label: { EmptyView() }
                )
            }
            .navigationBarHidden(true)
            .onAppear {
                SFSpeechRecognizer.requestAuthorization { _ in
                    // Обработка статуса, если нужно
                }
            }
        }
    }
    
    // MARK: Верхняя панель
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Задачи")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search", text: $presenter.searchText)
                    .foregroundColor(.white)
                    .onChange(of: presenter.searchText) { newValue in
                        presenter.updateSearchText(newValue)
                    }
                Image(systemName: "mic.fill")
                    .foregroundColor(isRecording ? .yellow : .gray)
                    .onTapGesture {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }
            }
            .padding(10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    // MARK: Нижняя панель
    private func bottomBarView(tasksCount: Int) -> some View {
        HStack {
            Text("\(tasksCount) Задач")
                .foregroundColor(.white)
            Spacer()
            Button {
                let newTask = TaskItem(
                    id: UUID(),
                    title: "Новая задача",
                    details: "Описание...",
                    date: Date(),
                    isCompleted: false
                )
                presenter.add(task: newTask)
                selectedTaskForDetail = newTask
                shouldFocusTitle = true
                isDetailActive = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .padding(.horizontal)
        .frame(height: 50)
        .background(Color.gray.opacity(0.5))
    }
    
    // MARK: - TaskRow
    // (Можно было бы вынести в отдельный файл, но сейчас тут)
    struct TaskRow: View {
        let task: TaskItem
        let toggleCompleted: () -> Void
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Button(action: toggleCompleted) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isCompleted ? .yellow : .gray)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(task.isCompleted ? .gray : .white)
                        .strikethrough(task.isCompleted, color: .gray)
                    Text(task.details)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    Text(formatDate(task.date))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Share Action
    private func shareTask(task: TaskItem) {
        let text = "\(task.title)\n\(task.details)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Голосовой ввод
    private func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка аудиосессии: \(error.localizedDescription)")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Невозможно создать SFSpeechAudioBufferRecognitionRequest")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                presenter.updateSearchText(result.bestTranscription.formattedString)
            }
            if error != nil || (result?.isFinal ?? false) {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                recognitionRequest.endAudio()
                self.recognitionRequest = nil
                self.recognitionTask = nil
                isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("audioEngine не запустился: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    var onUpdate: (String, String, Date) -> Void
    var focusTitle: Bool

    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isTitleFocused: Bool
    
    @State private var newTitle: String
    @State private var newDetails: String
    @State private var newDate: Date
    @State private var isEditingDate = false
    
    init(task: TaskItem, onUpdate: @escaping (String, String, Date) -> Void, focusTitle: Bool) {
        self.task = task
        self.onUpdate = onUpdate
        self.focusTitle = focusTitle
        _newTitle = State(initialValue: task.title)
        _newDetails = State(initialValue: task.details)
        _newDate = State(initialValue: task.date)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Кнопка назад
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .foregroundColor(.yellow)
                }
                .font(.system(size: 16, weight: .regular))
                
                // Поле ввода
                TextField("", text: $newTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .focused($isTitleFocused)
                
                // Выбор даты
                VStack(alignment: .leading, spacing: 4) {
                    Text("Дата")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    if isEditingDate {
                        DatePicker("", selection: $newDate, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .background(Color.black) // Чтобы колесо тоже было на чёрном фоне
                            .environment(\.colorScheme, .dark) // Точно тёмный стиль
                        
                        Button("Готово") {
                            withAnimation { isEditingDate = false }
                        }
                        .foregroundColor(.yellow)
                    } else {
                        Text(formatDate(newDate))
                            .foregroundColor(.white)
                            .onTapGesture {
                                withAnimation { isEditingDate = true }
                            }
                    }
                }
                
                // Описание задачи
                TextEditor(text: $newDetails)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(minHeight: 100)
                    .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
        .environment(\.colorScheme, .dark) // <-- ключ к тёмному оформлению
        .navigationBarHidden(true)
        .onAppear {
            if focusTitle {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTitleFocused = true
                }
            }
        }
        .onDisappear {
            onUpdate(newTitle, newDetails, newDate)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
}
