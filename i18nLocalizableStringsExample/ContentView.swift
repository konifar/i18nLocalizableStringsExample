//
//  ContentView.swift
//  i18nLocalizableStringsExample
//
//  Created by Yusuke Konishi on 2023/07/08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("hello.world")
            Text("hello.\("konifar")")
            Text("\(100).percent")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
