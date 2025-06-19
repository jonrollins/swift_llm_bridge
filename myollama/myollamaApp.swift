//
//  myollamaApp.swift
//  myollama
//
//  Created by rtlink on 6/11/25.
//

import SwiftUI
import Toasts


@main
struct myollamaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .installToast(position: .top)

        }
    }
}
