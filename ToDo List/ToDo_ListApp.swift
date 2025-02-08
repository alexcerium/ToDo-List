//
//  ToDo_ListApp.swift
//  ToDo List
//
//  Created by Aleksandr on 06.02.2025.
//

import SwiftUI
import Foundation

import SwiftUI

@main
struct MyToDoApp: App {
    @State private var showSplash = true  // Сначала показываем Splash

    var body: some Scene {
        WindowGroup {
            if showSplash {
                // Экран Splash (анимированный)
                SplashView(isActive: $showSplash)
            } else {
                // После Splash переходим к VIPER-модулю через TaskRouter
                TaskRouter.createContentView()
            }
        }
    }
}
