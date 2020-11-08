//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI
import AVFoundation
import CoreData


struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: Graph.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.graphId, ascending: true)])
    var graphs: FetchedResults<Graph>
    
    var body: some View {
        return GraphSelector(graphCount: graphs.count)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
