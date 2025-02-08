//
//  SplashView.swift
//  ToDo List
//
//  Created by Aleksandr on 07.02.2025.
//

import SwiftUI

struct SplashView: View {
    // Через эту привязку мы узнаём, когда убирать Splash
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Анимированный текст посередине экрана
            ShimmerText(text: "My ToDo List", fontSize: 44)
        }
        .onAppear {
            // Запустим таймер на 2 сек, после чего скрываем Splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}


/// Текст, по которому "пробегает" градиент
struct ShimmerText: View {
    let text: String
    let fontSize: CGFloat
    
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.yellow, .white, .yellow]),
            startPoint: startPoint,
            endPoint: endPoint
        )
        // "Вырезаем" градиент поверх текста
        .mask(
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
        )
        .onAppear {
            // Запускаем анимацию "туда-сюда"
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                startPoint = .trailing
                endPoint = .leading
            }
        }
    }
}
