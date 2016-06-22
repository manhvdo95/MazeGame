//
//  GameScene.swift
//  MazeGame
//
//  Created by Manh on 6/10/16.
//  Copyright (c) 2016 PaperDo. All rights reserved.
//

import SpriteKit
import AVFoundation

enum BodyType:UInt32 {
    
    case hero = 1
    case boundary = 2
    case sensorUp = 4
    case sensorDown = 8
    case sensorRight = 16
    case sensorLeft = 32
    case star = 64
    case enemy = 128
    case boundary2 = 256
    
}


class GameScene: SKScene, SKPhysicsContactDelegate, NSXMLParserDelegate {
    
    var currentSpeed:Float = 5
    var enemySpeed:Float = 4
    var heroLocation:CGPoint = CGPointZero
    var mazeWorld:SKNode = SKNode()
    var hero:Hero?
    var useTMXFiles:Bool = false
    var heroIsDead:Bool = false
    var starsAcquired:Int = 0
    var starsTotal:Int = 0
    var enemyCount:Int = 0
    var enemyDictionary:[String : CGPoint] = [:] // key is the String and the value is the CGPoint
    var currentTMXFile:String?
    var nextSKSFile:String?
    var bgImage:String?     // never used?
    var enemyLogic:Double = 5
    var gameLabel:SKLabelNode?
    var parallaxBG:SKSpriteNode?
    var parallaxOffset:CGPoint = CGPointZero
    var bgSoundPlayer:AVAudioPlayer?
    
    override func didMoveToView(view: SKView) {
        
        /* parse Property List aka GameData.plist */
        
        let path = NSBundle.mainBundle().pathForResource("GameData", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)!
        let heroDict:NSDictionary = dict.objectForKey("HeroSettings")! as! NSDictionary
        let gameDict:NSDictionary = dict.objectForKey("GameSettings")! as! NSDictionary
        let levelArray:AnyObject = dict.objectForKey("LevelSettings")!
        
        if let levelNSArray:NSArray = levelArray as? NSArray {
            
            var levelDict:NSDictionary = levelNSArray[currentLevel] as! NSDictionary
            
            if let tmxFile = levelDict["TMXFile"] as? String {
                currentTMXFile = tmxFile
                print("Specified a Tmx file for this level")
            }
            if let sksFile = levelDict["NextSKSFile"] as? String {
                nextSKSFile = sksFile
                print("Specified a next SKS file if this elvel is passed")
            }
            if let speed = levelDict["Speed"] as? Float {
                currentSpeed = speed
                print(currentSpeed)
            }
            if let espeed = levelDict["EnemySpeed"] as? Float {
                enemySpeed = espeed
                print(enemySpeed)
            }
            if let elogic = levelDict["EnemyLogic"] as? Double {
                enemyLogic = elogic
                print( enemyLogic )
            }
            if let bg = levelDict["Background"] as? String {
                bgImage = bg
            }
            if let musicFile = levelDict["Music"] as? String {
                playBackgroundSound(musicFile)
            }
        }
        
        
        
        self.backgroundColor = SKColor.blackColor()
        view.showsPhysics = gameDict["ShowPhysics"] as! Bool
        

        if(gameDict["Gravity"] != nil) {
            let newGravity:CGPoint = CGPointFromString(gameDict["Gravity"] as AnyObject? as! String)
            physicsWorld.gravity = CGVector(dx: newGravity.x, dy: newGravity.y)
        }
        else { // not using GameData.plist
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        }
        
        
        // MARK: PARALLAX
        if (gameDict["ParallaxOffset"] != nil) {
            
            let parallaxOffsetAsString = gameDict["ParallaxOffset"] as! String
            parallaxOffset = CGPointFromString(parallaxOffsetAsString)
            
        }
        
        
        physicsWorld.contactDelegate = self
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        useTMXFiles = gameDict["UseTMXFile"] as! Bool
        
        if(useTMXFiles == true) {
            //print("setup with tmx")
            
            self.enumerateChildNodesWithName("*") {
                node, stop in
                
                node.removeFromParent()
            }
            
            mazeWorld = SKNode()
            addChild(mazeWorld)
            
        }
        else {
            
            mazeWorld = childNodeWithName("mazeWorld")!
            heroLocation = (mazeWorld.childNodeWithName("StartingPoint")!.position)
            
        }
      
        
        /* hero and maze */
        hero = Hero(theDict: heroDict as! Dictionary)
        hero!.position = heroLocation
        mazeWorld.addChild(hero!)
        hero!.currentSpeed = currentSpeed // will get replaced later on a per level basis
        
        /* add background */
        if (bgImage != nil) {
            createBackground(bgImage!)
        }
        
        /* gestures */
        let waitAction:SKAction = SKAction.waitForDuration(0.5)
        self.runAction(waitAction, completion: {
            
            let swipeRight:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedRight:"))
            swipeRight.direction = .Right
            view.addGestureRecognizer(swipeRight)
            
            let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedLeft:"))
            swipeLeft.direction = .Left
            view.addGestureRecognizer(swipeLeft)
            
            let swipeUp:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedUp:"))
            swipeUp.direction = .Up
            view.addGestureRecognizer(swipeUp)
            
            let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedDown:"))
            swipeDown.direction = .Down
            view.addGestureRecognizer(swipeDown)
        })
        
        /* Set up based on TMX or SKS */
        if(useTMXFiles == false) {
            setUpBoundaryFromSKS()
            setUpEdgeFromSKS()
            setUpStarsFromSKS()
            setUpEnemiesFromSKS()
        }
        else {
            
            parseTMXFileWithName(currentTMXFile!)
            
            
        }
        
        tellEnemiesWhereHeroIs()
        createLabel()
    }
    
    func setUpEnemiesFromSKS() {
        mazeWorld.enumerateChildNodesWithName("enemy*") {
            node, stop in
            
            if let enemy = node as? SKSpriteNode {
                
                self.enemyCount++
                
                let newEnemy:Enemy = Enemy(fromSKSWithImage: enemy.name!) // getting the node with name "enemy" in GameScene.sks
                
                self.mazeWorld.addChild(newEnemy)
                newEnemy.position = enemy.position
                newEnemy.name = enemy.name!
                newEnemy.enemySpeed = self.enemySpeed
                self.enemyDictionary.updateValue(newEnemy.position, forKey: newEnemy.name!)
                
                enemy.removeFromParent()
                
            }
        }
    }
    
    func setUpBoundaryFromSKS() {
        mazeWorld.enumerateChildNodesWithName("boundary") {
            node, stop in
            
            if let boundary = node as? SKSpriteNode {
                
                //print("found boundary")
                let rect:CGRect = CGRect(origin: boundary.position, size: boundary.size)
                let newBoundary:Boundary = Boundary(fromSKSWithRect: rect, isEdge: false)
                self.mazeWorld.addChild(newBoundary)
                newBoundary.position = boundary.position
                
                boundary.removeFromParent()
                
            }
            
        }
    }
    
    func setUpEdgeFromSKS() {
        mazeWorld.enumerateChildNodesWithName("edge") {
            node, stop in
            
            if let edge = node as? SKSpriteNode {
                
                let rect:CGRect = CGRect(origin: edge.position, size: edge.size)
                let newEdge:Boundary = Boundary(fromSKSWithRect: rect, isEdge: true)
                self.mazeWorld.addChild(newEdge)
                newEdge.position = edge.position
                
                edge.removeFromParent()
                
            }
            
        }
    }
    
    func setUpStarsFromSKS() {
        mazeWorld.enumerateChildNodesWithName("star") {
            node, stop in
            
            if let star = node as? SKSpriteNode {
                
                let newStar:Star = Star()
                self.mazeWorld.addChild(newStar)
                newStar.position = star.position
                
                self.starsTotal++
                print(self.starsTotal)
                
                star.removeFromParent()
                
            }
            
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
    }
   
    override func update(currentTime: CFTimeInterval) {
        
        if(heroIsDead == false) {
            
            if (hero != nil){
                hero!.update()
            }
            
            mazeWorld.enumerateChildNodesWithName("enemy*") {
                node, stop in
                
                if let enemy = node as? Enemy {
                    
                    
                    if(enemy.isStuck == true) {
                        
                        enemy.heroLocationIs = self.returnTheDirection(enemy)
                        enemy.decideDirection()
                        enemy.isStuck = false
                    }
                    enemy.update()
                    
                }
            }
        }
        else {
            // HERO IS DEAD
            
            resetEnemies()
            
            hero!.rightBlocked = false
            hero!.position = heroLocation // this makes it so if the hero is dead, its position will be its spawning point
            heroIsDead = false
            hero!.currentDirection = .Right
            hero!.desiredDirection = .None
            hero!.goRight()
            hero!.runAnimation()
        }
        
    }
    
    
    // MARK: Swiped Gestures
    
    func swipedRight(sender:UISwipeGestureRecognizer) {
        
        hero!.goRight()
        
    }
    func swipedLeft(sender:UISwipeGestureRecognizer) {
        
        hero!.goLeft()
        
    }
    func swipedDown(sender:UISwipeGestureRecognizer) {
        
        hero!.goDown()
        
    }
    func swipedUp(sender:UISwipeGestureRecognizer) {
        
        hero!.goUp()
        
    }
    
    
    // MARK: Contact
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch(contactMask) {
 
        case BodyType.hero.rawValue | BodyType.enemy.rawValue:
            reloadLevel()
            //print("Contact")
            
        // contact with sensor start
        case BodyType.boundary.rawValue | BodyType.sensorUp.rawValue:
            hero!.upSensorContactStart()
            
        case BodyType.boundary.rawValue | BodyType.sensorDown.rawValue:
            hero!.downSensorContactStart()
        
        case BodyType.boundary.rawValue | BodyType.sensorLeft.rawValue:
            hero!.leftSensorContactStart()
            
        case BodyType.boundary.rawValue | BodyType.sensorRight.rawValue:
            hero!.rightSensorContactStart()
            
            
        case BodyType.hero.rawValue | BodyType.star.rawValue:
            
            let collectSound:SKAction = SKAction.playSoundFileNamed("collect_something.caf", waitForCompletion: false)
            self.runAction(collectSound)
            
            
            if let star = contact.bodyA.node as? Star {
                star.removeFromParent()
                
                if ( star.willAutoAdvanceLevel == true){
                    
                    loadNextLevel()
                    
                }
                
                
            } else if let star = contact.bodyB.node as? Star {
                
                star.removeFromParent()
                
                if ( star.willAutoAdvanceLevel == true){
                    
                    loadNextLevel()
                    
                }
                
            }
            
            starsAcquired += 1
            
            if (starsAcquired == starsTotal) {
                
                loadNextLevel()
            }
            
            
        default:
            return
            
        }

        
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch(contactMask) {
            
        // contact with sensor end
        case BodyType.boundary.rawValue | BodyType.sensorUp.rawValue:
            hero!.upSensorContactEnd()
            
        case BodyType.boundary.rawValue | BodyType.sensorDown.rawValue:
            hero!.downSensorContactEnd()
            
        case BodyType.boundary.rawValue | BodyType.sensorLeft.rawValue:
            hero!.leftSensorContactEnd()
            
        case BodyType.boundary.rawValue | BodyType.sensorRight.rawValue:
            hero!.rightSensorContactEnd()
            
        default:
            return
            
        }

        
    }
    
    // MARK: Parse TMX Files
    
    // TODO: change the parameter to name:String
    func parseTMXFileWithName(name:NSString) {
        let path:String = NSBundle.mainBundle().pathForResource(name as String, ofType: "tmx")!
        let data:NSData = NSData(contentsOfFile: path)!
        let parser:NSXMLParser = NSXMLParser(data: data)
        
        parser.delegate = self
        parser.parse()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if(elementName == "object") {
            
            let type:AnyObject? = attributeDict["type"]
            //print(type)
            
            if(type as? String == "Boundary") {
                
                var tmxDict = attributeDict
                tmxDict.updateValue("false", forKey: "isEdge")
                
                let newBoundary:Boundary = Boundary(theDict: tmxDict)
                mazeWorld.addChild(newBoundary)
                
            }
            else if(type as? String == "Edge") {
                
                var tmxDict = attributeDict
                tmxDict.updateValue("true", forKey: "isEdge")
                
                let newBoundary:Boundary = Boundary(theDict: tmxDict)
                mazeWorld.addChild(newBoundary)
            }
                
            else if(type as? String == "Star") {
                
                let newStar:Star = Star(fromTMXFileWithDict: attributeDict)
                mazeWorld.addChild(newStar)
                
                starsTotal++
                
            }
            else if(type as? String == "Portal") {
                
                let theName:String = attributeDict["name"] as AnyObject? as! String
                
                if(theName == "StartingPoint") {
                    let theX:String = attributeDict["x"] as AnyObject? as! String
                    let x:Int = Int(theX)!
                    
                    let theY:String = attributeDict["y"] as AnyObject? as! String
                    let y:Int = Int(theY)!
                    
                    hero!.position = CGPoint(x: x, y: y * -1) // mulitply -1 because it starts at bottomLeft
                    heroLocation = hero!.position
       
                }
            }
            else if(type as? String == "Enemy") {
                
                enemyCount++
                
                let theName:String = attributeDict["name"] as AnyObject? as! String
                
                let newEnemy:Enemy = Enemy(theDict: attributeDict)
                mazeWorld.addChild(newEnemy)
                
                newEnemy.name = theName
                newEnemy.enemySpeed = enemySpeed
                
                let location:CGPoint = newEnemy.position
                enemyDictionary.updateValue(location, forKey: newEnemy.name!)
                
            }
        }
        
    }
    
    
    // MARK: Camera On Hero / Parallax
    
    override func didSimulatePhysics() {
        
        if(heroIsDead == false) {
            if ( hero != nil){
                self.centerOnNode(hero!)
            }
        }
        
    }
    
    func centerOnNode(node:SKNode) {
        let cameraPositionInScene:CGPoint = self.convertPoint(node.position, fromNode: mazeWorld)
        mazeWorld.position = CGPoint(x: mazeWorld.position.x - cameraPositionInScene.x, y: mazeWorld.position.y - cameraPositionInScene.y)
        
        /* handle parallax */
        
        if (parallaxOffset.x != 0) {
            
            if ( Int(cameraPositionInScene.x) < 0 ) {
                
                parallaxBG!.position = CGPoint(x: parallaxBG!.position.x + parallaxOffset.x, y: parallaxBG!.position.y)
                
            } else if ( Int(cameraPositionInScene.x) > 0 ) {
                
                parallaxBG!.position = CGPoint(x: parallaxBG!.position.x - parallaxOffset.x, y: parallaxBG!.position.y)
            }
            
            
        }
        
        if (parallaxOffset.y != 0) {
            
            if ( Int(cameraPositionInScene.y) < 0 ) {
                
                parallaxBG!.position = CGPoint(x: parallaxBG!.position.x , y: parallaxBG!.position.y + parallaxOffset.y)
                
                
            } else if ( Int(cameraPositionInScene.y) > 0 ) {
                
                parallaxBG!.position = CGPoint(x: parallaxBG!.position.x , y: parallaxBG!.position.y - parallaxOffset.y )
            }
            
        }

        
    }
    
    
    // MARK: Enemy Stuff
    
    func tellEnemiesWhereHeroIs() {
        
        let enemyAction:SKAction = SKAction.waitForDuration(enemyLogic)
        self.runAction(enemyAction, completion: {
            
                self.tellEnemiesWhereHeroIs()
        
            })
        
        mazeWorld.enumerateChildNodesWithName("enemy*") {
            node, stop in
        
            if let enemy = node as? Enemy {
                enemy.heroLocationIs = self.returnTheDirection(enemy)
            }
        }
    }
    
    func returnTheDirection(enemy:Enemy) -> HeroIs {
        
        if(self.hero!.position.x < enemy.position.x && self.hero!.position.y < enemy.position.y) {
            return HeroIs.SouthWest
            
        }
        else if(self.hero!.position.x > enemy.position.x && self.hero!.position.y < enemy.position.y) {
            return HeroIs.SouthEast
            
        }
        else if(self.hero!.position.x < enemy.position.x && self.hero!.position.y > enemy.position.y) {
            return HeroIs.NorthWest
            
        }
        else if(self.hero!.position.x > enemy.position.x && self.hero!.position.y > enemy.position.y) {
            return HeroIs.NorthEast
            
        } else {
            return HeroIs.NorthEast
        }

    }
    
    
    // MARK: Reload Level
    
    func reloadLevel() {
        loseLife()
        heroIsDead = true
        
    }
    
    func resetEnemies() {
        // name is key, location is value
        for(name, location) in enemyDictionary {
            mazeWorld.childNodeWithName(name)?.position = location
        }
    }
    
    func loadNextLevel() {
        
        currentLevel++
        
        if (bgSoundPlayer != nil) {
            
            bgSoundPlayer!.stop()
            bgSoundPlayer = nil
            
        }
        
        if(useTMXFiles == true) {
            loadNextTMXLevel()
        }
        else {
            loadNextSKSLevel()
        }
        
    }
    
    func loadNextTMXLevel() {
    
        let scene:GameScene = GameScene(size: self.size)
        scene.scaleMode = .AspectFill
        
        self.view?.presentScene(scene, transition: SKTransition.fadeWithDuration(1))
        
    }
    
    func loadNextSKSLevel() {
        currentSKSFile = nextSKSFile!
        
        var scene = GameScene(fileNamed:currentSKSFile)
        scene!.scaleMode = .AspectFill
        
        self.view?.presentScene(scene!, transition: SKTransition.fadeWithDuration(1))

    }
    
    func loseLife() {
        
        livesLeft = livesLeft - 1
        
        if(livesLeft == 0) {
            // show text label with Game Over
            
            gameLabel!.text = "Game Over"
            gameLabel!.position = CGPointZero
            gameLabel!.horizontalAlignmentMode = .Center
            
            let scaleAction:SKAction = SKAction.scaleTo(0.2, duration: 3)
            let fadeAction:SKAction = SKAction.fadeAlphaTo(0, duration: 3)
            let group:SKAction = SKAction.group([scaleAction, fadeAction])
            
            mazeWorld.runAction(group, completion: {
                
                self.resetGame()
                
            })
            
        }
        else {
            // update text for lives label
            gameLabel!.text = "Lives: " + String(livesLeft)
        }
        
    }
    
    func resetGame() {
        
        livesLeft = 3
        currentLevel = 0
        
        
        if (bgSoundPlayer != nil) {
            
            bgSoundPlayer!.stop()
            bgSoundPlayer = nil
            
        }

        
        if(useTMXFiles == true) {
            
            loadNextTMXLevel()
            
        }
        else {
        
            currentSKSFile = firstSKSFile
            
            var scene = GameScene(fileNamed:currentSKSFile)
            scene!.scaleMode = .AspectFill
            
            self.view?.presentScene(scene!, transition: SKTransition.fadeWithDuration(1))

        }
        
    }
    
    // MARK: DEVICE ON LABEL?
    
    func createLabel() {
        gameLabel = SKLabelNode(fontNamed: "BM germar")
        gameLabel!.horizontalAlignmentMode = .Left
        gameLabel!.verticalAlignmentMode = .Center
        gameLabel?.fontColor = SKColor.whiteColor()
        gameLabel?.text = "Lives: " + String(livesLeft)
        
        addChild(gameLabel!)
        
        if(UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            
            gameLabel!.position = CGPoint(x: -(self.size.width / 2.3), y: -(self.size.height / 3))
            
        }
        else if(UIDevice.currentDevice().userInterfaceIdiom == .Pad) {

            gameLabel!.position = CGPoint(x: -(self.size.width / 2.3), y: -(self.size.height / 2.3))
            
        }
        else {
            gameLabel!.position = CGPoint(x: -(self.size.width / 2.3), y: -(self.size.height / 3))
        }
        
    }
    
    func createBackground(image:String) {
        
        parallaxBG = SKSpriteNode(imageNamed: image)
        mazeWorld.addChild(parallaxBG!)
        parallaxBG!.position = CGPoint(x: parallaxBG!.size.width / 2 , y: -parallaxBG!.size.height / 2)
        parallaxBG!.alpha = 0.5
    }
    
    // MARK: Background Sound
    func playBackgroundSound(name:String) {
        
        
        if (bgSoundPlayer != nil) {
            
            bgSoundPlayer!.stop()
            bgSoundPlayer = nil
            
        }
        
        
        let fileURL:NSURL = NSBundle.mainBundle().URLForResource( name , withExtension: "mp3")!
        
        do {
            bgSoundPlayer = try AVAudioPlayer(contentsOfURL: fileURL)
        } catch _ {
            bgSoundPlayer = nil
        }
        
        
        bgSoundPlayer!.volume = 0.5  //half volume
        bgSoundPlayer!.numberOfLoops = -1
        bgSoundPlayer!.prepareToPlay()
        bgSoundPlayer!.play()
        
        
    }

    
}










