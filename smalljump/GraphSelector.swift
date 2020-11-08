//
//  GraphSelector.swift
//  smalljump
//
//  Created by cjc on 11/6/20.
//

import SwiftUI

struct GraphSelector: View {
    @Environment (\.managedObjectContext) var moc
    
    @FetchRequest(entity: Graph.entity(),
                  // i.e. want to retrieve them in a consistent order, just like when they were created
                  // could also do this sorting outside or elsewhere?
                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.id, ascending: true)])
    var graphs: FetchedResults<Graph>
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct GraphSelector_Previews: PreviewProvider {
    static var previews: some View {
        GraphSelector().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
