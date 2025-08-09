//
//  CustomTabView.swift
//  ClipboardApp
//
//  Custom user-defined tabs
//

import SwiftUI

struct CustomTabView: View {
    let tabName: String
    
    var body: some View {
        VStack {
            Text("Custom Tab: \(tabName)")
                .font(.headline)
                .padding()
            
            Text("Custom tabs will be implemented in Phase 4")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
    }
}

#Preview {
    CustomTabView(tabName: "Passwords")
}