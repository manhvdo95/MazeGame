//
//  Hero.swift
//  MazeGame
//
//  Created by Manh on 6/10/16.
//  Copyright © 2016 PaperDo. All rights reserved.
//

import Foundation
import SpriteKit


enum Direction {
    
    case Up, Down, Right, Left, None
    
}

enum DesiredDirection {
    
    case Up, Down, Right, Left, None
    
}

class Hero:SKNode {
    
    var currentSpeed:Float = 5
    var currentDirection = Direction.Right
    var desiredDirection = DesiredDirection.None
    
    var movingAnimation:SKAction?
    var objectSprite:SKSpriteNode?
    
    var downBlocked:Bool = false
    var upBlocked:Bool = false
    var leftBlocked:Bool = false
    var rightBlocked:Bool = false
    
    var nodeUp:SKNode?
    var nodeDown:SKNode?
    var nodeLeft:SKNode?
    var nodeRight:SKNode?
    
    var buffer:Int = 25
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(theDict:[String:AnyObject]) {
        
        super.init()
        //print(theDict)
        
        let image:String = theDict["HeroImage"] as AnyObject? as! String
        
        objectSprite = SKSpriteNode(imageNamed: image)
        addChild(objectSprite!)
        
        // using GameData.plist
        if let atlastName:String = theDict["MovingAtlasFile"] as AnyObject? as? String {
            
            let frameArray:AnyObject = theDict["MovingFrames"]!
            
            if let framesAsNSArray:NSArray = frameArray as? NSArray {
                setUpAnimationWithArray(framesAsNSArray, andAtlasNamed: atlastName)
                runAnimation()
            }
            
        }
        else { // not using GameData.plist
            setUpAnimation()
            runAnimation()
        }
        
        
        let largerSize:CGSize = CGSize(width: objectSprite!.size.width * 1.2, height: objectSprite!.size.height * 1.2)
        
        let bodyShape:String = theDict["BodyShape"] as AnyObject? as! String
        
        // have to change in GameData.plist to use
        if(bodyShape == "circle") {
            self.physicsBody = SKPhysicsBody(circleOfRadius: objectSprite!.size.width / 2)
        }
        else {
            self.physicsBody = SKPhysicsBody(rectangleOfSize: objectSprite!.size)
        }
        
        self.physicsBody?.friction = 0  // 0 is slippery like marble
        self.physicsBody?.dynamic = true // Wheather or not its part of the overall physics simulation
        // true keeps the object within boundaries better
        self.physicsBody?.restitution = 0 // how bouncy it is
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.affectedByGravity = false
        
        self.physicsBody?.categoryBitMask = BodyType.hero.rawValue
        //self.physicsBody?.collisionBitMask = 0 // wont collide with anything , by default collides with everything // Also the object that the hero is colliding with dynamic must be set to false
        self.physicsBody?.contactTestBitMask = BodyType.boundary.rawValue | BodyType.star.rawValue
        
        //SENSORS
        nodeUp = SKNode()
        addChild(nodeUp!)
        nodeUp!.position = CGPoint(x: 0, y: buffer)
        createUpSensorPhysicsBody(false)
        
        nodeDown = SKNode()
        addChild(nodeDown!)
        nodeDown!.position = CGPoint(x: 0, y: -buffer)
        createDownSensorPhysicsBody(false)
        
        nodeRight = SKNode()
        addChild(nodeRight!)
        nodeRight!.position = CGPoint(x: buffer, y: 0)
        createRightSensorPhysicsBody(true)
        
        nodeLeft = SKNode()
        addChild(nodeLeft!)
        nodeLeft!.position = CGPoint(x: -buffer, y: 0)
        createLeftSensorPhysicsBody(true)
        
        
    }
    
    // MARK: Update
    
    func update() {
        
        switch currentDirection {
            
        case .Right:
            self.position = CGPoint(x: self.position.x + CGFloat(currentSpeed), y: self.position.y)
            objectSprite!.zRotation = CGFloat(degreesToRadian(0))
        case .Left:
            self.position = CGPoint(x: self.position.x - CGFloat(currentSpeed), y: self.position.y)
            objectSprite!.zRotation = CGFloat(degreesToRadian(180))
        case .Up:
            self.position = CGPoint(x: self.position.x, y: self.position.y + CGFloat(currentSpeed))
            objectSprite!.zRotation = CGFloat(degreesToRadian(90))
        case .Down:
            self.position = CGPoint(x: self.position.x, y: self.position.y - CGFloat(currentSpeed))
            objectSprite!.zRotation = CGFloat(degreesToRadian(270))
        case .None:
            self.position = CGPoint(x: self.position.x, y: self.position.y)
        }
    }
    
    // MARK: Helper Functions
    
    func degreesToRadian(degree: Double) -> Double {
        return degree / 180 * Double(M_PI)
    }
    
    func goUp() {
        
        if(upBlocked == true) {
            desiredDirection = DesiredDirection.Up
        }
        else {
            
            currentDirection = .Up
            desiredDirection = .None
            runAnimation()
            
            downBlocked = false
            self.physicsBody?.dynamic = true
            
            createUpSensorPhysicsBody(true)
            createDownSensorPhysicsBody(true)
            createLeftSensorPhysicsBody(false)
            createRightSensorPhysicsBody(false)
        }
    }
    
    func goDown() {
        
        if(downBlocked == true) {
            desiredDirection = DesiredDirection.Down
        }
        else {
            currentDirection = .Down
            desiredDirection = .None
            runAnimation()
            
            upBlocked = false
            self.physicsBody?.dynamic = true
            
            createUpSensorPhysicsBody(true)
            createDownSensorPhysicsBody(true)
            createLeftSensorPhysicsBody(false)
            createRightSensorPhysicsBody(false)
        }
    }
    
    func goRight() {
        
        if(rightBlocked == true) {
            desiredDirection = DesiredDirection.Right
        }
        else {
            currentDirection = .Right
            desiredDirection = .None
            runAnimation()
            
            leftBlocked = false
            self.physicsBody?.dynamic = true
            
            createUpSensorPhysicsBody(false)
            createDownSensorPhysicsBody(false)
            createLeftSensorPhysicsBody(true)
            createRightSensorPhysicsBody(true)
        }
    }
    
    func goLeft() {
        
        if(leftBlocked == true) {
            desiredDirection = DesiredDirection.Left
        }
        else {
            currentDirection = .Left
            desiredDirection = .None
            runAnimation()
            
            rightBlocked = false
            self.physicsBody?.dynamic = true
            
            createUpSensorPhysicsBody(false)
            createDownSensorPhysicsBody(false)
            createLeftSensorPhysicsBody(true)
            createRightSensorPhysicsBody(true)
        }
    }
    
    
    // MARK: Animation
    
    func setUpAnimationWithArray(theArray:NSArray, andAtlasNamed theAtlas:String) {
        
        let atlas = SKTextureAtlas(named: theAtlas) // without the .atlas extension
        
        var atlasTextures:[SKTexture] = []
        
        for i in 0 ..< theArray.count {
            let texture:SKTexture = atlas.textureNamed(theArray[i] as! String)
            atlasTextures.insert(texture, atIndex: i)
        }
        
        let atlasAnimation = SKAction.animateWithTextures(atlasTextures, timePerFrame: 1.0 / 30, resize: true, restore: false)
        movingAnimation = SKAction.repeatActionForever(atlasAnimation)
        
    }
    
    func setUpAnimation() {
        
        let atlas = SKTextureAtlas(named: "moving")
        let array:[String] = ["moving0001", "moving0002", "moving0003", "moving0004", "moving0003", "moving0002"]
        
        var atlasTextures:[SKTexture] = []
        
        for i in 0 ..< array.count {
            let texture:SKTexture = atlas.textureNamed(array[i])
            atlasTextures.insert(texture, atIndex: i)
        }
        
        let atlasAnimation = SKAction.animateWithTextures(atlasTextures, timePerFrame: 1.0 / 30, resize: true, restore: false)
        movingAnimation = SKAction.repeatActionForever(atlasAnimation)
        
    }
    
    func runAnimation() {
        
        objectSprite?.runAction(movingAnimation!)
        
    }
    
    func stopAnimation() {
        objectSprite?.removeAllActions()
    }
    
    
    // MARK: Create Sensor Physics Body
    
    func createUpSensorPhysicsBody( whileTravellingUpOrDown:Bool) {
        
        var size:CGSize = CGSizeZero
        
        if(whileTravellingUpOrDown == true) {
            size = CGSize(width: 32, height: 9)
        }
        else {
            size = CGSize(width: 32.4, height: 36)
        }
        
        nodeUp!.physicsBody = nil // get rid of any existing physics body
        let bodyUp:SKPhysicsBody = SKPhysicsBody(rectangleOfSize: size)
        nodeUp!.physicsBody = bodyUp
        nodeUp!.physicsBody?.categoryBitMask = BodyType.sensorUp.rawValue
        nodeUp!.physicsBody?.collisionBitMask = 0
        nodeUp!.physicsBody?.contactTestBitMask = BodyType.boundary.rawValue
        nodeUp!.physicsBody?.pinned = true // basicly pinned to its parent aka the ship
        nodeUp!.physicsBody?.allowsRotation = false
    }
    
    func createDownSensorPhysicsBody(whileTravellingUpOrDown:Bool) {
        
        var size:CGSize = CGSizeZero
        
        if(whileTravellingUpOrDown == true) {
            size = CGSize(width: 32, height: 9)
        }
        else {
            size = CGSize(width: 32.4, height: 36)
        }
        
        nodeDown!.physicsBody = nil // get rid of any existing physics body
        let bodyDown:SKPhysicsBody = SKPhysicsBody(rectangleOfSize: size)
        nodeDown!.physicsBody = bodyDown
        nodeDown!.physicsBody?.categoryBitMask = BodyType.sensorDown.rawValue
        nodeDown!.physicsBody?.collisionBitMask = 0
        nodeDown!.physicsBody?.contactTestBitMask = BodyType.boundary.rawValue
        nodeDown!.physicsBody?.pinned = true // basicly pinned to its parent aka the ship
        nodeDown!.physicsBody?.allowsRotation = false
        
    }
    
    func createLeftSensorPhysicsBody(whileTravellingLeftOrRight:Bool) {
        
        var size:CGSize = CGSizeZero
        
        if(whileTravellingLeftOrRight == true) {
            size = CGSize(width: 9, height: 32)
        }
        else {
            size = CGSize(width: 36, height: 32.4)
        }
        
        nodeLeft?.physicsBody = nil // get rid of any existing physics body
        let bodyLeft:SKPhysicsBody = SKPhysicsBody(rectangleOfSize: size)
        nodeLeft!.physicsBody = bodyLeft
        nodeLeft!.physicsBody?.categoryBitMask = BodyType.sensorLeft.rawValue
        nodeLeft!.physicsBody?.collisionBitMask = 0
        nodeLeft!.physicsBody?.contactTestBitMask = BodyType.boundary.rawValue
        nodeLeft!.physicsBody?.pinned = true // basicly pinned to its parent aka the ship
        nodeLeft!.physicsBody?.allowsRotation = false
        
    }
    
    func createRightSensorPhysicsBody(whileTravellingLeftOrRight:Bool) {
        
        var size:CGSize = CGSizeZero
        
        if(whileTravellingLeftOrRight == true) {
            size = CGSize(width: 9, height: 32)
        }
        else {
            size = CGSize(width: 36, height: 32.4)
        }
        
        nodeRight?.physicsBody = nil // get rid of any existing physics body
        let bodyRight:SKPhysicsBody = SKPhysicsBody(rectangleOfSize: size)
        nodeRight!.physicsBody = bodyRight
        nodeRight!.physicsBody?.categoryBitMask = BodyType.sensorRight.rawValue
        nodeRight!.physicsBody?.collisionBitMask = 0
        nodeRight!.physicsBody?.contactTestBitMask = BodyType.boundary.rawValue
        nodeRight!.physicsBody?.pinned = true // basicly pinned to its parent aka the ship
        nodeRight!.physicsBody?.allowsRotation = false
        
    }
    
    // MARK: Functions for Sensor Contact INITIATED
    
    func upSensorContactStart() {
        
        upBlocked = true
        
        if(currentDirection == Direction.Up) {
            currentDirection = Direction.None
            self.physicsBody?.dynamic = false
            stopAnimation()
        }
    }
    
    func downSensorContactStart() {
        
        downBlocked = true
        
        if(currentDirection == Direction.Down) {
            currentDirection = Direction.None
            self.physicsBody?.dynamic = false
            stopAnimation()
        }
    }
    
    func leftSensorContactStart() {
        
        leftBlocked = true
        
        if(currentDirection == Direction.Left) {
            currentDirection = Direction.None
            self.physicsBody?.dynamic = false
            stopAnimation()
        }
    }
    
    func rightSensorContactStart() {
        
        rightBlocked = true
        
        if(currentDirection == Direction.Right) {
            currentDirection = Direction.None
            self.physicsBody?.dynamic = false
            stopAnimation()
        }
    }
    
    
    // MARK: Functions for Sensor Contact ENDED
    
    func upSensorContactEnd() {
        
        upBlocked = false
        
        if(desiredDirection == DesiredDirection.Up) {
            goUp()
            desiredDirection == DesiredDirection.None
        }
    }
    
    func downSensorContactEnd() {
        
        downBlocked = false
        
        if(desiredDirection == DesiredDirection.Down) {
            goDown()
            desiredDirection == DesiredDirection.None
        }
    }
    
    func leftSensorContactEnd() {
        leftBlocked = false
        
        if(desiredDirection == DesiredDirection.Left) {
            goLeft()
            desiredDirection == DesiredDirection.None
        }
    }
    
    func rightSensorContactEnd() {
        rightBlocked = false
        
        if(desiredDirection == DesiredDirection.Right) {
            goRight()
            desiredDirection == DesiredDirection.None
        }
    }
    
    
}















