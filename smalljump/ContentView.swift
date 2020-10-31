//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI

struct ContentView: View {
    @State private var scale: CGFloat = 1.0
    
//    local state to store amount of drag
    // added CGSize
    @State private var dragAmount: CGSize = CGSize.zero
    @State private var dragAmount2: CGSize = CGSize.zero
    @State private var dragAmount3: CGSize = CGSize.zero
    
    // make one liner?
    // make into a class, since you're handling / using local state
    // ... can you do that? can you put the state in the class instead of the view?
    func ball(top: Color, bottom: Color, width: CGFloat, height: CGFloat) -> some View {
        LinearGradient(gradient: Gradient(colors: [top, bottom]), startPoint: .topLeading, endPoint: .bottomTrailing)
            // width and height are SAME for circle...
            .frame(width: width, height: height)
            .clipShape(Circle())
    }
    
    struct MovingCircle: View {

        @State private var dragged = CGSize.zero
        @State private var accumulated = CGSize.zero

        var body: some View {
            
            // solve the 'reset problem' by:
            // keeping track of how much we've moved
            
            
            // note: CGSize has two dimensions: width, height
            // onChange and onEnded callbacks receive a value
            
        
            
            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.green]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .frame(width: 60, height: 60).border(Color.red)
                
                // what is the offset, such that it would be the `dragged`, rather than the `accumulated`?
                .offset(x: self.dragged.width, y: self.dragged.height)
            

                .gesture(DragGesture()
                    .onChanged{ value in
                        // while we're dragging, we only modify `dragged`
                        self.dragged = CGSize(width: value.translation.width + self.accumulated.width, height: value.translation.height + self.accumulated.height)
                }
                .onEnded{ value in
//                    once we've finished dragging, we update the
                    self.dragged = CGSize(width: value.translation.width + self.accumulated.width, height: value.translation.height + self.accumulated.height)
                    self.accumulated = self.dragged
                    }
                ).animation(.spring())
        }
    }
    
    
    var body: some View {
        VStack {
            ball(top: Color.white, bottom: Color.black, width: 75, height: 125)
                .offset(dragAmount3)
                .gesture(DragGesture()
                            .onChanged { self.dragAmount3 = $0.translation }
                            .onEnded { _ in
                                withAnimation(.spring()) { self.dragAmount3 = .zero }
                            })
            LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 100, height: 200)
                .clipShape(Circle())
                .offset(dragAmount2)
                // `onChanged()`: fn calls whnver the user moves their finger
                // `onEnded` fn calld
                .gesture(DragGesture()
                            // 'translation of the drag' = how far we moved from start point
                            .onChanged { self.dragAmount2 = $0.translation }
                            .onEnded { _ in
                                withAnimation(.spring()) { self.dragAmount2 = .zero }
                            })
            
            LinearGradient(gradient: Gradient(colors: [.yellow, .red]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .frame(width: 100, height: 100).border(Color.black)
    
                // offset adjusts the X and Y cordinate of a view without moving other views around it
                // without an offset the circle can't move?
                .offset(dragAmount)
                
                        
                // we create a drag gesture and attach it to the card
                // `onChanged()`: fn calls whnver the user moves their finger
                // `onEnded` fn calld
                .gesture(DragGesture()
                            // 'translation of the drag' = how far we moved from start point
                            .onChanged { self.dragAmount = $0.translation }
                
                            // even with this, we still reset the items position upon next drag
                            .onEnded { self.dragAmount = $0.translation }
                )
            
            MovingCircle()
                
                
//                            .onEnded { _ in
//
//                                // there may be a bug
////                                let _ = print("hi")
////                                print("hey there!")
////                                print("i was dragged")
//
//                                // this previously was moving the circle back to its original home
//                                // disabling
//                                withAnimation(.spring())
////                                    { self.dragAmount = .zero }
//                                        { self.dragAmount = $0.translation }
//                            })
        
        }
        
        
        
        

    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



// GROWING IMAGE
//struct ContentView: View {
////    @State private var scale: CGFloat = 1.0
////
////    var body: some View {
//////        Text("Hello, world!").padding()
////
////        // an image that gets bigger when you click it!
////        Image(systemName: "photo")
////            .scaleEffect(scale)
////            .gesture(TapGesture()
////                        .onEnded {_ in self.scale += 0.1
////                        })
///
/////
///Image(systemName: "photo")
//.scaleEffect(scale)
//.gesture(LongPressGesture(minimumDuration: 2)
//            .onEnded {_ in self.scale += 0.5})
////
///
///       // works for dragging gesture,
// but does not necessarily have animation
//Image(systemName: "photo")
//    .scaleEffect(scale)
//    .gesture(DragGesture(minimumDistance: 25)
//                .onEnded { _ in self.scale += 0.7})
///
////    }
////}
