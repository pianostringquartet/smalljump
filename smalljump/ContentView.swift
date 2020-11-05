//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI
import AVFoundation
import CoreData

/* ----------------------------------------------------------------
 UTILS
 ---------------------------------------------------------------- */

// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            log("Unable to play sound.")
        }
    }
}


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
}

// Preference key for preference data
struct BallPreferenceKey: PreferenceKey {
    typealias Value = [BallPreferenceData]
    
    static var defaultValue: [BallPreferenceData] = []
    
    static func reduce(value: inout [BallPreferenceData], nextValue: () -> [BallPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}


/* ----------------------------------------------------------------
 DOMAIN TYPES: representations of domain concepts
 ---------------------------------------------------------------- */

//struct Connection: Identifiable, Equatable {
//    let id: UUID = UUID()
//    let from: Int
//    let to: Int
//
//    static func ==(lhs: Connection, rhs: Connection) -> Bool {
//        // Edgeless connection:
//        return lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from
//    }
//}


/* ----------------------------------------------------------------
 UI ELEMENTS: draggable balls, etc.
 ---------------------------------------------------------------- */

struct Line: Shape {
    let from, to: CGPoint
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
    }
}

func line(from: CGPoint, to: CGPoint) -> some View {
    Line(from: from, to: to).stroke().animation(.default)
}

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}

//struct Ball: View {
//    @State private var position = CGSize.zero
//    @State private var previousPosition = CGSize.zero
//
//    @State private var isAnchored: Bool = true // true just iff ball has NEVER 'been moved enough'
//
//    @Binding public var connections: [Connection]
//    @Binding public var nodeCount: Int
//    @Binding public var connectingNode: Int?
//
//    // Node info
//    @State private var info: UUID = UUID()
//    @State private var showPopover: Bool = false
//
//    let nodeNumber: Int
//    let radius: CGFloat
//
//    init(nodeNumber: Int, radius: CGFloat, connections: Binding<[Connection]>, nodeCount: Binding<Int>, connectingNode: Binding<Int?>) {
//        self.nodeNumber = nodeNumber
//        self.radius = radius
//        self._connections = connections
//        self._nodeCount = nodeCount
//        self._connectingNode = connectingNode
//    }
//
//    private func determineColor() -> Color {
//        if connectingNode == nodeNumber {
//            return Color.pink
//        }
//        else if !isAnchored {
//            return Color.blue
//        }
//        else {
//            return
//                position == CGSize.zero ?
//                    Color.white.opacity(0) :
//                    Color.blue.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
//        }
//    }
//
//    var body: some View {
//        Circle().stroke(Color.black)
//            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
//                VStack (spacing: 20) {
//                    Text("Node Number: \(nodeNumber)")
//                    Text("Node ID: \(info)")
//                }
//                .padding()
//            }
//            .background(Image(systemName: "plus"))
//            .overlay(LinearGradient(gradient: Gradient(colors: [
//                                                        // white of opacity 0 means: 'invisible'
//                                                        position == CGSize.zero ? Color.white.opacity(0) : Color.white,
//                                                           determineColor()]),
//                               startPoint: .topLeading,
//                               endPoint: .bottomTrailing
//                ))
//            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
//            .frame(width: radius, height: radius)
//            // Child stores its center in anchor preference data,
//            // for parent to later access.
//            // NOTE: must come before .offset modifier
//            .anchorPreference(key: BallPreferenceKey.self,
//                              value: .center, // center for Anchor<CGPoint>
//                              transform: { [BallPreferenceData(viewIdx: self.nodeNumber, center: $0)] })
//            .offset(x: self.position.width, y: self.position.height)
//            .gesture(DragGesture()
//                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
//                        .onEnded { (value: DragGesture.Value) in
//                            if isAnchored {
//                                let minDistance: CGFloat = CGFloat(90)
//                                // Did we move the node enough for it to become a free, de-anchored node?
//                                let movedEnough: Bool =
//                                    abs(value.translation.width) > minDistance ||
//                                    abs(value.translation.height) > minDistance
//                                if movedEnough {
//                                    self.isAnchored.toggle()
//                                    self.previousPosition = self.position
//                                    self.nodeCount += 1
//                                    playSound(sound: "positive_ping", type: "mp3")
//                                }
//                                else {
//                                    withAnimation(.spring()) { self.position = .zero }
//                                }
//                            }
//                            else {
//                                self.previousPosition = self.position
//                            }
//                        })
//
//            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
//            .onTapGesture(count: 2, perform: {
//                if !isAnchored {
//                    self.showPopover.toggle()
//                }
//            })
//            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
//                if !isAnchored {
//                    let existsConnectingNode: Bool = connectingNode != nil
//                    let isConnectingNode: Bool = existsConnectingNode && connectingNode == nodeNumber
//
//                    // Note: if no existing connecting node, make this node the connecting node
//                    // ie user is attempting to create or remove a node
//                    if !existsConnectingNode {
//                        self.connectingNode = self.nodeNumber
//                    }
//                    else { // ie there is an connecting node:
//                        // CORE DATA:
//                        let edge: Connection = Connection(from: connectingNode!, to: self.nodeNumber)
//
//                        let edgeAlreadyExists: Bool = connections.contains(edge)
//
//                        // if exist connecting node and I am the connecting node, cancel ie set connecting node=nil
//                        if isConnectingNode {
//                            self.connectingNode = nil
//                        }
//                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
//                        // remove the connection and set connecting node=nil
//                        else if !isConnectingNode && edgeAlreadyExists {
//                            // CORE DATA:
//                            self.connections = connections.filter { $0 != edge }
//                            self.connectingNode = nil
//                            playSound(sound: "connection_removed", type: "mp3")
//                        }
//                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
//                        // add the connection and set connecting node=nil
//                        else if !isConnectingNode && !edgeAlreadyExists {
//                            self.connections.append(edge)
//                            self.connectingNode = nil
//                            playSound(sound: "connection_added", type: "mp3")
//                        }
//                    }
//                }
//            })
//    }
//}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */


// method for saving
//func saveContext() {
//  do {
//    try managedObjectContext.save()
//  } catch {
//    print("Error saving managed object context: \(error)")
//  }
//}


struct ContentView: View {
    @Environment(\.managedObjectContext) var moc

    // from: https://www.hackingwithswift.com/books/ios-swiftui/how-to-combine-core-data-and-swiftui
    @FetchRequest(entity: Student.entity(), sortDescriptors: [])
    
    var students: FetchedResults<Student>
    
//    @FetchRequest(entity: Connection.entity(), sortDescriptors: [])
//    var connections: FetchedResults<Connection>

    @State private var nodeCount: Int = 1 // start with one node

    // all existings edges
//    @State public var connections: [Connection] = []

    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil

//    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: Country.entity(), sortDescriptors: []) var countries: FetchedResults<Country>
    
    
    var body: some View {
        
        VStack {
            List {
                ForEach(countries, id: \.self) { country in
                    Section(header: Text(country.wrappedFullName)) {
                        ForEach(country.candyArray, id: \.self) { candy in
                            Text(candy.wrappedName)
                        }
                    }
                }
            }

            Button("Add") {
                let candy1 = Candy(context: self.moc)
                candy1.name = "Mars"
                candy1.origin = Country(context: self.moc)
                candy1.origin?.shortName = "UK"
                candy1.origin?.fullName = "United Kingdom"

                let candy2 = Candy(context: self.moc)
                candy2.name = "KitKat"
                candy2.origin = Country(context: self.moc)
                candy2.origin?.shortName = "UK"
                candy2.origin?.fullName = "United Kingdom"

                let candy3 = Candy(context: self.moc)
                candy3.name = "Twix"
                candy3.origin = Country(context: self.moc)
                candy3.origin?.shortName = "UK"
                candy3.origin?.fullName = "United Kingdom"

                let candy4 = Candy(context: self.moc)
                candy4.name = "Toblerone"
                candy4.origin = Country(context: self.moc)
                candy4.origin?.shortName = "CH"
                candy4.origin?.fullName = "Switzerland"

                try? self.moc.save()
            }
        }
        
        
//        VStack {
//            List {
//               ForEach(students, id: \.id) { student in
////                ForEach(students, id: \.id) { (student: Student) in
//                   Text(student.name ?? "Unknown")
//               }
//
//            }
//            Button("Add") {
//                let firstNames = ["Ginny", "Harry", "Hermione", "Luna", "Ron"]
//                let lastNames = ["Granger", "Lovegood", "Potter", "Weasley"]
//
//                let chosenFirstName = firstNames.randomElement()!
//                let chosenLastName = lastNames.randomElement()!
//
//                // we give the CD-defined model the managedObjectContext key
//                let student = Student(context: self.moc)
//
//                student.id = UUID()
//                student.name = "\(chosenFirstName) \(chosenLastName)"
//                log("about to try to save")
//                try? self.moc.save()
//            }
//        }
        

//        VStack { // HACK: bottom right corner alignment
//
//
//
//            Spacer()
//            HStack {
//                Spacer()
//                ZStack {
//                    ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> Ball in
//                        Ball(nodeNumber: nodeNumber,
//                            radius: 60,
//                            connections: $connections,
//                            nodeCount: $nodeCount,
//                            connectingNode: $connectingNode)
//
//                    }.padding(.trailing, 30).padding(.bottom, 30)
//                }
//            }
//        }
//        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
//            if connections.count >= 1 && nodeCount >= 2 {
//                GeometryReader { (geometry: GeometryProxy) in
//                    ForEach(connections, content: { (connection: Connection) in
//                        // Note: we must convert the node number to an index position
//                        let toPref: BallPreferenceData = preferences[connection.to - 1]
//                        let fromPref: BallPreferenceData = preferences[connection.from - 1]
//                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
//
//                    })
//                }
//            }
//        }
    }
}




/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView()
            // note the use of the `preview` property
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        
        
//        ContentViewExample().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


/* ----------------------------------------------------------------
 EXAMPLE FOR ITEMS
 ---------------------------------------------------------------- */

//struct ContentView: View {
struct ContentViewExample: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        VStack (spacing: 20) {
            Button(action: addItem) {
                Label("Add Item", systemImage: "plus")
            }
            EditButton()
            List {
                ForEach(items) { item in
                    Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                }
                .onDelete(perform: deleteItems)
            }
        }
        
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
