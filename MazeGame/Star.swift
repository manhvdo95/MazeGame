//
//  Star.swift
//  MazeGame
//
//  Created by Manh on 6/13/16.
//  Copyright © 2016 PaperDo. All rights reserved.
//

import Foundation
import SpriteKit

class Star:SKNode {

    var willAutoAdvanceLevel:Bool = false
    var starSprite:SKSpriteNode?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        
        super.init()
        starSprite = SKSpriteNode(imageNamed: "star")
        addChild(starSprite!)
        
        createPhysicsBody()
        
    }
    
    init(fromTMXFileWithDict theDict:Dictionary<NSObject, AnyObject>) {
        
        super.init()
        
        let theX:String = theDict["x"] as AnyObject? as! String
        let x:Int = Int(theX)!
        
        let theY:String = theDict["y"] as AnyObject? as! String
        let y:Int = Int(theY)!

        let location:CGPoint = CGPoint(x: x, y: y * -1)
        starSprite = SKSpriteNode(imageNamed: "star")
        addChild(starSprite!)
        
        self.position = CGPoint(x: location.x + (starSprite!.size.width / 2), y: location.y - (starSprite!.size.height / 2)) // must use this because Tiled uses position in the topLeft of the shape
        
        createPhysicsBody()
        
    }
    
    func createPhysicsBody() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: starSprite!.size.width / 2)
        
        self.physicsBody?.categoryBitMask = BodyType.star.rawValue
        self.physicsBody?.collisionBitMask = 0 // 0 means no collision with anything
        self.physicsBody?.contactTestBitMask = BodyType.hero.rawValue
        
        self.zPosition = 90
    }
    
    
}
