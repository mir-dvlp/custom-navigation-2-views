//
//  ContentView.swift
//  Custom Navigation (2 views)
//
//  Created by Михаил Иванов on 31.01.2025.
//

import SwiftUI

struct ContentView: View {
    //Для виброотклика
    @State private var taskIsComplete = true
    
    //Показать следующий View
    @State private var isViewPresented: Bool = false
    
    var body: some View {
        CustomNavigationView(taskIsComplete: $taskIsComplete, isViewPresented: $isViewPresented, mainView: {
            HomeView(goToDetail: {
                withAnimation(.smooth(duration: 0.4)) {
                    isViewPresented = true
                    taskIsComplete.toggle()
                }
            })
        }, newView: {
            NextView(goBack: {
                withAnimation(.smooth(duration: 0.4)) {
                    isViewPresented = false
                    taskIsComplete.toggle()
                }
            })
        })
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.background).fill(.green.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct CustomNavigationView<MainView:View, NewView:View>: View {
    
    //Для виброотклика
    @Binding var taskIsComplete: Bool
    
    //Показать следующий View
    @Binding var isViewPresented: Bool
    
    //Общее смещение
    @State private var offset: CGSize = .zero
    
    //Смещение следующего View
    @State private var viewOffset: CGSize = .zero
    
    //Изменение скругления следующего View при жесте от правого края
    @State private var viewCornerRadius: CGFloat = 0.0
    
    // Множитель scale при жесте от правого края
    @State private var viewScale: CGFloat = 1.0
    
    @ViewBuilder var mainView: MainView
    @ViewBuilder var newView: NewView

    var body: some View {
        ZStack {
            // Главный экран
            mainView
            .offset(x: isViewPresented ? min(0, -(UIScreen.main.bounds.width / 3) + offset.width / 3) : 0, y: 0)
            .disabled(isViewPresented)
            
            //Переход к новому экрану
            navigateToView
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 1), trigger: taskIsComplete)
    }
    
    @ViewBuilder
    var navigateToView: some View {
        ZStack {
            // Затемнение
            Color.black
                .opacity(isViewPresented ? min(0.4, 0.4 - (Double(offset.width / 1000))) : 0.0)
            
            if isViewPresented {
                
                // Новый экран
                newView
                .zIndex(1)
                .background(RoundedRectangle(cornerRadius: max(24, 24 + (Double(viewCornerRadius / 12))), style: .continuous).fill(.background).fill(.orange.opacity(0.2)))
                .offset(x: viewOffset.width) // Смещаем экран
                .overlay(
                    HStack{
                        //Жест от левого края
                        Color.clear.frame(maxWidth: UIScreen.main.bounds.width / 32)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if gesture.translation.width > 0 {
                                            withAnimation(.smooth(duration: 0.4)) {
                                                viewOffset.width = gesture.translation.width
                                                offset.width = gesture.translation.width
                                            }
                                        }
                                    }
                                    .onEnded { gesture in
                                        if gesture.translation.width > UIScreen.main.bounds.width / 4 {
                                            withAnimation(.smooth(duration: 0.4)) {
                                                
                                                taskIsComplete.toggle()
                                                viewOffset.width = UIScreen.main.bounds.width
                                                offset.width = UIScreen.main.bounds.width
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                
                                                isViewPresented = false
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                                    viewOffset = .zero
                                                    offset = .zero
                                                }
                                            }
                                        } else {
                                            withAnimation(.smooth(duration: 0.4)) {
                                                viewOffset = .zero
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
            
                        Spacer()
                        
                        //Жест от правого края
                        Color.clear.frame(maxWidth: UIScreen.main.bounds.width / 32)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if gesture.translation.width < 0 {
                                            withAnimation(.smooth(duration: 0.4)) {
                                                viewOffset.width = abs(gesture.translation.width)
                                                offset.width = abs(gesture.translation.width)
                                                viewScale = 1 - (abs(gesture.translation.width) / 1000)
                                                viewCornerRadius = abs(gesture.translation.width)
                                            }
                                        }
                                    }
                                    .onEnded { gesture in
                                        if abs(gesture.translation.width) > UIScreen.main.bounds.width / 4 {
                                            withAnimation(.smooth(duration: 0.4)) {
                                                
                                                isViewPresented = false
                                                taskIsComplete.toggle()
                                                
                                                viewScale = 1.0
                                                viewCornerRadius = 0
                                                
                                                viewOffset = .zero
                                                offset = .zero
                                            }
                                        } else {
                                            withAnimation(.smooth(duration: 0.4)) {
                                                viewScale = 1.0
                                                viewCornerRadius = 0
                                                
                                                viewOffset = .zero
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                    }
                ) // Зоны жестов
                .scaleEffect(CGFloat(viewScale))
                .transition(.move(edge: .trailing))
            }
        }
    }
}

struct HomeView: View {
    var goToDetail: () -> Void

    var body: some View {
        VStack {
            Text("Главный экран")
                .font(.largeTitle)
                .padding()

            Button(action: goToDetail) {
                Text("Перейти к деталям")
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule(style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NextView: View {
    
    var goBack: () -> Void
    
    //Для виброотклика
    @State private var taskIsComplete = true
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    @State private var isDragging = false
    
    //Смещение следующего View
    @State private var viewOffset: CGSize = .zero
    
    // Множитель scale при жесте от правого края
    @State private var viewScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            VStack {
                Text("Детали")
                    .font(.largeTitle)
                    .padding()
                
                Button(action: goBack) {
                    Text("Назад")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 16)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule(style: .continuous))
                        
                }
                .disabled(isDragging)
            }
            .offset(offset)
            .scaleEffect(scale)
            .gesture(
                LongPressGesture(minimumDuration: 0.4)
                    .onEnded { value in
                        withAnimation(.bouncy(duration: 0.3)) {
                            scale = 1.2
                            isDragging = true
                        }
                    }
                    .sequenced(before: DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            withAnimation(.snappy(duration: 0.3)) {
                                offset = gesture.translation
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                               offset = .zero
                               isDragging = false
                            }
                            // После завершения драга запускаем масштабирование
                            withAnimation(.spring(duration: 0.2)) {
                                scale = 1.3
                            }
                            // Возвращаем масштаб и вращение в исходное состояние
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(duration: 0.2)) {
                                    scale = 1.0
                                }
                            }
                        })
            )
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 1), trigger: taskIsComplete)
        
        
    }
}

#Preview {
    ContentView()
}
