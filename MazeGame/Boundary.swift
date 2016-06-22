//
//  Boundary.swift
//  MazeGame
//
//  Created by Manh on 6/12/16.
//  Copyright © 2016 PaperDo. All rights reserved.
//

import Foundation
import SpriteKit

class Boundary:SKNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(fromSKSWithRect rect:CGRect, isEdge:Bool) {
        super.init()
        
        let newLocation = CGPoint(x: -(rect.size.width / 2), y: -(rect.size.height / 2))
        let newRect:CGRect = CGRect(origin: newLocation, size: rect.size)
        
        createBoundary(newRect, createAsEdge: isEdge)
        
    }
    
    init(theDict:Dictionary<NSObject, AnyObject>) {
        super.init()
        
        let isEdgeAsString:String = theDict["isEdge"] as AnyObject? as! String
        
        var isEdge:Bool
        
        if(isEdgeAsString == "true") {
            isEdge = true
        }
        else {
            isEdge = false
        }
        
        let theX:String = theDict["x"] as AnyObject? as! String
        let x:Int = Int(theX)!
        
        let theY:String = theDict["y"] as AnyObject? as! String
        let y:Int = Int(theY)!
        
        let theWidth:String = theDict["width"] as AnyObject? as! String
        let width:Int = Int(theWidth)!
        
        let theHeight:String = theDict["height"] as AnyObject? as! String
        let height:Int = Int(theHeight)!
        
        /* Refers to the program "Tiled" and multiply by -1 becasue spritekit starts at bottomLeft and 
            "Tiled" starts at topLeft.
         */
        let location:CGPoint = CGPoint(x: x, y: y * -1)
        let size:CGSize = CGSize(width: width, height: height)
        
        self.position = CGPoint(x: location.x + (size.width / 2), y: location.y - (size.height / 2))
        let rect:CGRect = CGRectMake(-(size.width / 2), -(size.height / 2), size.width, size.height)
        
        createBoundary(rect, createAsEdge: isEdge)
        
    }
    
    func createBoundary(rect:CGRect, createAsEdge:Bool) {
    
        let shape = SKShapeNode(rect: rect, cornerRadius: 19)
        shape.fillColor = SKColor.clearColor()
        shape.strokeColor = SKColor.whiteColor()
        shape.lineWidth = 1
        
        addChild(shape)
        
        if(createAsEdge == false) {
            self.physicsBody = SKPhysicsBody(rectangleOfSize: rect.size)
        }
        else {
            self.physicsBody = SKPhysicsBody(edgeLoopFromRect: rect)
        }
        
        self.physicsBody!.dynamic = false // because its false, it wont move
        self.physicsBody!.categoryBitMask = BodyType.boundary.rawValue
        self.physicsBody!.friction = 0
        self.physicsBody!.allowsRotation = false
        
        self.zPosition = 100
        
    }
   
    
}
