//
//  ContentView.swift
//  Fidget Spins
//
//  Created by Elliot Williams on 2025-06-22.
//

import UIKit
import CoreMotion

class FidgetSpinnerViewController: UIViewController {
    
    // MARK: - Properties
    private let spinner = UIImageView()
    private let motionManager = CMMotionManager()
    private var displayLink: CADisplayLink?
    private var angularVelocity: CGFloat = 0
    private var rotationAngle: CGFloat = 0
    private var position = CGPoint.zero
    private var velocity = CGPoint.zero
    private var lastUpdateTime: TimeInterval = 0
    private var currentGravity = CGVector(dx: 0, dy: 0)
    
    // Physics constants
    private let friction: CGFloat = 0.98
    private let shakeBoost: CGFloat = 20
    private let gravityMultiplier: CGFloat = 500
    private let rotationSensitivity: CGFloat = 0.5
    private let bounceDamping: CGFloat = 0.7
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpinner()
        setupMotionUpdates()
        startDisplayLink()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
        displayLink?.invalidate()
    }
    
    // MARK: - Setup
    private func setupSpinner() {
        // Configure spinner appearance
        spinner.image = UIImage(systemName: "circle.hexagongrid.fill")?
            .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        spinner.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        spinner.center = view.center
        view.addSubview(spinner)
        
        position = spinner.center
    }
    
    private func setupMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            self.handleDeviceMotion(motion)
        }
    }
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    // MARK: - Motion Handling
    private func handleDeviceMotion(_ motion: CMDeviceMotion) {
        // 1. Get gravity vector
        currentGravity = CGVector(dx: motion.gravity.x,
                                  dy: -motion.gravity.y) // Flip Y for iOS coordinate system
        
        // 2. Detect shake using user acceleration
        let acceleration = motion.userAcceleration
        let accelerationMagnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2)
        
        if accelerationMagnitude > 2.0 {
            // Apply boost when shaken
            angularVelocity += shakeBoost
        }
        
        // 3. Add rotation based on device twist (z-axis rotation)
        angularVelocity += CGFloat(motion.rotationRate.z) * rotationSensitivity
    }
    
    // MARK: - Physics Update
    @objc private func updateFrame(displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        let deltaTime: CGFloat
        
        if lastUpdateTime > 0 {
            deltaTime = CGFloat(currentTime - lastUpdateTime)
        } else {
            deltaTime = 1.0 / 60.0 // Approximate first frame
        }
        
        lastUpdateTime = currentTime
        
        // Update rotation
        rotationAngle += angularVelocity * deltaTime
        spinner.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        // Apply friction
        angularVelocity *= pow(friction, deltaTime * 60)
        
        // Update position based on gravity
        velocity.dx += currentGravity.dx * gravityMultiplier * deltaTime
        velocity.dy += currentGravity.dy * gravityMultiplier * deltaTime
        
        position.x += velocity.dx * deltaTime
        position.y += velocity.dy * deltaTime
        
        // Apply boundary collision
        handleBoundaryCollision()
        
        // Update view position
        spinner.center = position
    }
    
    private func handleBoundaryCollision() {
        let halfWidth = spinner.bounds.width / 2
        let halfHeight = spinner.bounds.height / 2
        let viewBounds = view.bounds.insetBy(dx: halfWidth, dy: halfHeight)
        
        // Horizontal boundaries
        if position.x < viewBounds.minX {
            position.x = viewBounds.minX
            velocity.dx = -velocity.dx * bounceDamping
        } else if position.x > viewBounds.maxX {
            position.x = viewBounds.maxX
            velocity.dx = -velocity.dx * bounceDamping
        }
        
        // Vertical boundaries
        if position.y < viewBounds.minY {
            position.y = viewBounds.minY
            velocity.dy = -velocity.dy * bounceDamping
        } else if position.y > viewBounds.maxY {
            position.y = viewBounds.maxY
            velocity.dy = -velocity.dy * bounceDamping
        }
    }
}
#Preview {
    ContentView()
}
