//
//  MainTabView.swift
//  T1D Stock
//
//  Created by Eissa Ahmad on 2025-12-11.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DexcomSensorsView()
                .tabItem {
                    Label("Dexcom Sensors", systemImage: "sensor.fill")
                }
            
            PlaceholderView(title: "Insulin Pens")
                .tabItem {
                    Label("Insulin Pens", systemImage: "syringe.fill")
                }
            
            PlaceholderView(title: "Needles")
                .tabItem {
                    Label("Needles", systemImage: "cross.case.fill")
                }
            
            PlaceholderView(title: "Test Strips")
                .tabItem {
                    Label("Test Strips", systemImage: "drop.fill")
                }
        }
    }
}

struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
    }
}