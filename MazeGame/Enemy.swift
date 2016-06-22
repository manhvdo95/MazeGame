//
//  Enemy.swift
//  MazeGame
//
//  Created by Manh on 6/14/16.
//  Copyright © 2016 PaperDo. All rights reserved.
//

import Foundation
import SpriteKit

enum HeroIs {
    
    case SouthWest, SouthEast, NorthWest, NorthEast
    
}

enum EnemyDirection {
    
    case Up, Down, Left, Right
    
}


class Enemy:SKNode {
    
    var heroLocationIs = HeroIs.SouthWest
    var currentDirection = EnemyDirection.Up
    var enemySpeed:Float = 5
    var isStuck:Bool = false
    
    var previousLocation1:CGPoint = CGPointZero
    var previousLocation2:CGPoint = CGPoint(x: 1, y: 1)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(fromSKSWithImage image:String) {
        super.init()
        
        let enemySprite = SKSpriteNode(imageNamed: image)
        addChild(enemySprite)
        
        setUpPhysics(enemySprite.size)
        
    }
    
    init(theDict:Dictionary<NSObject, AnyObject>) {
        super.init()
        
        let theX:String = theDict["x"] as AnyObject? as! String
        let x:Int = Int(theX)!
        
        let theY:String = theDict["y"] as AnyObject? as! String
        let y:Int = Int(theY)!
        
        let location:CGPoint = CGPoint(x: x, y: y * -1)
        
        let image = theDict["name"] as AnyObject? as! String
        let enemySprite = SKSpriteNode(imageNamed: image)
        
        self.position = CGPoint(x: location.x + (enemySprite.size.width / 2), y: location.y - (enemySprite.size.height / 2)) // must use this because Tiled uses position in the top left of the shape
        
        addChild(enemySprite)
        setUpPhysics(enemySprite.size)
        
    }
    
    func setUpPhysics(size:CGSize) {
        
        //self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody = SKPhysicsBody(rectangleOfSize: size)
        self.physicsBody?.categoryBitMask = BodyType.enemy.rawValue
        self.physicsBody?.collisionBitMask = BodyType.boundary.rawValue | BodyType.boundary2.rawValue
        self.physicsBody?.contactTestBitMask = BodyType.hero.rawValue | BodyType.enemy.rawValue
        self.physicsBody?.allowsRotation = false
        self.zPosition = 90
    }
    
    func decideDirection() {
        
        let previousDirection = currentDirection
        
        switch (heroLocationIs) {
            
        case .SouthWest:
            if(previousDirection == .Down) {
                currentDirection = .Left
            }
            else {
                currentDirection = .Down
            }
        case .SouthEast:
            if(previousDirection == .Down) {
                currentDirection = .Right
            }
            else {
                currentDirection = .Down
            }
        case .NorthEast:
            if(previousDirection == .Up) {
                currentDirection = .Right
            }
            else {
                currentDirection = .Up
            }
        case .NorthWest:
            if(previousDirection == .Up) {
                currentDirection = .Left
            }
            else {
                currentDirection = .Up
            }
        }
        
        
        
    }
    
    
    func update() {
        /* Check if enemy is stuck, that means has stayed in same location for more than one update */
        if(Int(previousLocation2.y) == Int(previousLocation1.y) && Int(previousLocation2.x) == Int(previousLocation1.x)) {
            // Stuck
            
            isStuck = true
            decideDirection()
            
        }
        
        ///////////////////////////////
        // this block of code makes it so the enemy randomly change direction from time to time
        
        let superDice = arc4random_uniform(1000)
        
        if(superDice == 0) {
            let diceRoll = arc4random_uniform(4)
            
            switch(diceRoll) {
            case 0:
                currentDirection = .Up
            case 1:
                currentDirection = .Left
            case 2:
                currentDirection = .Right
            default:
                currentDirection = .Down
                
                
            }
            //////////////////////////////
        }
        
            
            /* Save a location variable prior to moving */
            
            previousLocation2 = previousLocation1
            
            
            
            /* Check direction enemy is moving, increment primarily in that direction; then add some to either
             left, right, up or down, depending on hero compass location
             */
            // Could have used a switch statement
            
            if(currentDirection == .Up) {
                
                self.position = CGPoint(x: self.position.x, y: self.position.y + CGFloat(enemySpeed))
                
                if(heroLocationIs == .NorthEast) {
                    self.position = CGPoint(x: self.position.x + CGFloat(enemySpeed), y: self.position.y)
                }
                else if(heroLocationIs == .NorthWest){
                    self.position = CGPoint(x: self.position.x - CGFloat(enemySpeed), y: self.position.y)
                }
                
            }
            else if(currentDirection == .Down) {
                
                self.position = CGPoint(x: self.position.x, y: self.position.y - CGFloat(enemySpeed))
                
                if(heroLocationIs == .SouthEast) {
                    self.position = CGPoint(x: self.position.x + CGFloat(enemySpeed), y: self.position.y)
                }
                else if(heroLocationIs == .SouthWest) {
                    self.position = CGPoint(x: self.position.x - CGFloat(enemySpeed), y: self.position.y)
                }
                
            }
            else if(currentDirection == .Right) {
                
                self.position = CGPoint(x: self.position.x + CGFloat(enemySpeed), y: self.position.y)
                
                if(heroLocationIs == .SouthEast) {
                    self.position = CGPoint(x: self.position.x, y: self.position.y - CGFloat(enemySpeed))
                }
                else if(heroLocationIs == .NorthEast) {
                    self.position = CGPoint(x: self.position.x, y: self.position.y + CGFloat(enemySpeed))
                }
                
            }
            else if(currentDirection == .Left) {
                
                self.position = CGPoint(x: self.position.x - CGFloat(enemySpeed), y: self.position.y)
                
                if(heroLocationIs == .SouthWest) {
                    self.position = CGPoint(x: self.position.x, y: self.position.y - CGFloat(enemySpeed))
                }
                else if(heroLocationIs == .NorthEast) {
                    self.position = CGPoint(x: self.position.x, y: self.position.y + CGFloat(enemySpeed))
                }
                
            }
            
            previousLocation1 = self.position
            
            /* After moving enemy, save location to another location variable, for comparing stuckness */
            
        }
    
    // enemies change direction upon contact with each other
    /*
    func bumped() {
        
        switch(currentDirection) {
            
        case .Up:
            currentDirection = .Down
        case .Down:
            currentDirection = .Up
        case .Left:
            currentDirection = .Right
        case.Right:
            currentDirection = .Left
        }
        
        
    }
     */
    
}





















