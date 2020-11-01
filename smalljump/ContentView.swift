//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI

func ball(top: Color, bottom: Color, width: CGFloat, height: CGFloat) -> some View {
    LinearGradient(gradient: Gradient(colors: [top, bottom]), startPoint: .topLeading, endPoint: .bottomTrailing)
        // width and height are SAME for circle...
        .frame(width: width, height: height)
        .clipShape(Circle())
}

struct ColoredCircle: View {

    @State private var dragged = CGSize.zero
    @State private var accumulated = CGSize.zero

    let topColor, bottomColor: Color
    let radius: CGFloat
    
    init(topColor: Color, bottomColor: Color, radius: CGFloat) {
        self.topColor = topColor
        self.bottomColor = bottomColor
        self.radius = radius
    }
    
    var body: some View {
    
        LinearGradient(gradient: Gradient(colors: [topColor, bottomColor]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .frame(width: radius, height: radius, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)//.frame(width: 60, height: 60) //.border(Color.red)
            .offset(x: self.dragged.width, y: self.dragged.height)
            .animation(.default)
            .gesture(DragGesture()
                .onChanged{ value in
                    self.dragged = CGSize(width: value.translation.width + self.accumulated.width, height: value.translation.height + self.accumulated.height)
                    
                }
                .onEnded{ value in
                    self.dragged = CGSize(width: value.translation.width + self.accumulated.width, height: value.translation.height + self.accumulated.height)
                    self.accumulated = self.dragged
                }
            )
    }
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
            .frame(width: 60, height: 60) //.border(Color.red)
            
            // what is the offset, such that it would be the `dragged`, rather than the `accumulated`?
            .offset(x: self.dragged.width, y: self.dragged.height)
        
            // animation here vs after .gesture?
            .animation(.default)
            
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
            )
    }
}


struct ContentView: View {
    @State private var scale: CGFloat = 1.0

//    local state to store amount of drag
    // added CGSize
    @State private var dragAmount: CGSize = CGSize.zero
    @State private var dragAmount2: CGSize = CGSize.zero
    @State private var dragAmount3: CGSize = CGSize.zero

    @State private var goalPipeline: String = "goal: f g h"
    @State private var currentPipeline: String = "current: "

    var body: some View {
        VStack {
            ball(top: Color.white, bottom: Color.black, width: 75, height: 125)
                .offset(dragAmount3)
                .gesture(DragGesture()
                            .onChanged { self.dragAmount3 = $0.translation }
                            .onEnded { _ in
                                withAnimation(.spring()) { self.dragAmount3 = .zero }
                            })
            ColoredCircle(topColor: .yellow, bottomColor: .green, radius: 75)
            ColoredCircle(topColor: .white, bottomColor: .pink, radius: 75)

            // TODO: needs to be placed at very bottom of screen,
            Text(goalPipeline).bold().font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            Text(currentPipeline).bold().font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
