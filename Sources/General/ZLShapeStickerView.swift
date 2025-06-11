//  This class should be placed inside ZLBaseStickerView.swift for organization.


import UIKit
// MARK: - ZLShapeStickerView
// The new class for rendering shapes
public class ZLShapeStickerView: ZLBaseStickerView {

    // MARK: - Properties
    let shapeType: ZLShapeType
    public var shapeColor: UIColor
    // Make the imageView public for debugging, can be changed back to private later.
    public let imageView: UIImageView

    /// This computed property is required by the base class. It "freezes" the current
    /// state of this sticker into a `ZLShapeStickerState` object. This is used for
    /// the undo/redo manager and for saving the final edit.
    override public var state: ZLBaseStickertState {
        return ZLShapeStickerState(
            id: id,
            shapeType: shapeType,
            shapeColor: shapeColor,
            image: imageView.image!,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }

    // MARK: - Initialization

    public init(shapeType: ZLShapeType, shapeColor: UIColor, originScale: CGFloat, originAngle: CGFloat, originFrame: CGRect) {
        self.shapeType = shapeType
        self.shapeColor = shapeColor
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        super.init(originScale: originScale, originAngle: originAngle, originFrame: originFrame, showBorder: true)
        addSubview(imageView)
        updateImage()
    }


    public init(state: ZLShapeStickerState) {
           self.shapeType = state.shapeType
           self.shapeColor = state.shapeColor
           self.imageView = UIImageView()
           self.imageView.contentMode = .scaleAspectFit
           super.init(id: state.id, originScale: state.originScale, originAngle: state.originAngle, originFrame: state.originFrame, gesScale: state.gesScale, gesRotation: state.gesRotation, totalTranslationPoint: state.totalTranslationPoint)
           addSubview(imageView)
           imageView.image = state.image
       }
    
    required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            // Ensure the image view always has the correct frame.
            imageView.frame = self.bounds
        }

        override public func setupUIFrameWhenFirstLayout() {
            super.setupUIFrameWhenFirstLayout()
            imageView.frame = self.bounds
        }
    
    public func update(color: UIColor) {
            print("✅ ZLShapeStickerView: update(color:) called with \(color.description)")
            guard color != self.shapeColor else {
                print("⚠️ Color is the same, not updating.")
                return
            }
            
            self.shapeColor = color
            self.updateImage()
        }

        private func updateImage() {
            print("✅ ZLShapeStickerView: updateImage() is running.")
            
            // Ensure bounds are not zero, which can happen during initialization.
            // If bounds are zero, the generated image will have zero size.
            let drawingSize = self.bounds.size.width > 0 ? self.bounds.size : self.originFrame.size
            print("... Drawing with size: \(drawingSize)")
            
            let template = ZLShapeStickerView.templateImage(for: shapeType, size: drawingSize)
            
            let tintedImage = template.zl_tinted(with: self.shapeColor)
            
            self.imageView.image = tintedImage
            
            if tintedImage != nil {
                print("... Successfully set new tinted image to imageView.")
            } else {
                print("... ❌ FAILED to create tinted image.")
            }
        }

    
    /// This is a static "factory" method that creates a white, template image for any given shape.
    /// It's static so it can be used by other classes (like `ShapeStickerContainerView`) without needing an instance.
public static func templateImage(for shapeType: ZLShapeType, size: CGSize) -> UIImage {
    let imageSize = size.width > 0 ? size : CGSize(width: 100, height: 100)
    let renderer = UIGraphicsImageRenderer(size: imageSize)
    
    let image = renderer.image { ctx in
        let rect = CGRect(origin: .zero, size: imageSize)
        
        // All shapes in the reference image are outlined (stroked)
        UIColor.white.setStroke()
        
        // A consistent line width for all shapes
        let lineWidth = max(2.0, imageSize.width / 20.0)
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        // Use a smaller inset to give icons more space
        let insetRect = rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.1)

        switch shapeType {
        case .arrow:
            let arrowInset = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.35)
            path.move(to: CGPoint(x: arrowInset.maxX - arrowInset.width * 0.5, y: arrowInset.minY))
            path.addLine(to: CGPoint(x: arrowInset.maxX, y: arrowInset.midY))
            path.addLine(to: CGPoint(x: arrowInset.maxX - arrowInset.width * 0.5, y: arrowInset.maxY))
            path.move(to: CGPoint(x: arrowInset.maxX, y: arrowInset.midY))
            path.addLine(to: CGPoint(x: arrowInset.minX, y: arrowInset.midY))

        case .rectangle:
            path.append(UIBezierPath(roundedRect: insetRect, cornerRadius: insetRect.width * 0.1))

        case .circle:
            path.append(UIBezierPath(ovalIn: insetRect))

        case .triangle:
            path.move(to: CGPoint(x: insetRect.midX, y: insetRect.minY))
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
            path.close()
            
        case .star:
            let center = CGPoint(x: insetRect.midX, y: insetRect.midY)
            let radius = insetRect.width / 2
            let pointsOnStar = 5
            var angle: CGFloat = -(.pi / 2.0)
            let angleIncrement = .pi * 2.0 / CGFloat(pointsOnStar)
            let innerRadius = radius * 0.38
            
            for i in 0..<(pointsOnStar * 2) {
                let r = (i % 2 == 0) ? radius : innerRadius
                let point = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
                angle += angleIncrement / 2.0
            }
            path.close()
            
        case .warning:
            // Draw the outer triangle
            let warningInset = insetRect
            path.move(to: CGPoint(x: warningInset.midX, y: warningInset.minY))
            path.addLine(to: CGPoint(x: warningInset.maxX, y: warningInset.maxY))
            path.addLine(to: CGPoint(x: warningInset.minX, y: warningInset.maxY))
            path.close()
            
            // Draw the exclamation mark inside
            path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.45))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.65))
            path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.75))
            path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.height * 0.75), radius: lineWidth / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            
        }
        
        path.stroke()
    }
    
    return image.withRenderingMode(.alwaysTemplate)
}
    
    /// A static helper to determine a good default size for a new sticker.
    class func calculateSize(width: CGFloat) -> CGSize {
        return CGSize(width: 120, height: 120)
    }
}

// Helper extension to scale normalized (0 to 1) points to a specific CGRect
fileprivate extension CGPoint {
    func scaled(to rect: CGRect, from canvasSize: CGFloat = 24) -> CGPoint {
        let scale = min(rect.width, rect.height) / canvasSize
        // Center the shape within the rect
        let offset = CGPoint(x: rect.minX + (rect.width - canvasSize * scale) / 2, y: rect.minY + (rect.height - canvasSize * scale) / 2)
        return CGPoint(x: self.x * scale + offset.x, y: self.y * scale + offset.y)
    }
}
// MARK: - ADD THIS HELPER EXTENSION

/// Add this extension to your project, e.g., at the bottom of the ZLBaseStickerView.swift file.
/// It provides a backward-compatible way to tint an image.
private extension UIImage {
    func zl_tinted(with color: UIColor) -> UIImage {
        // Use the modern API if available.
        if #available(iOS 13.0, *) {
            // After tinting, immediately get a version with the original rendering mode.
            // This "bakes in" the color and stops it from being a template.
            return self.withTintColor(color).withRenderingMode(.alwaysOriginal) // <-- FIX IS HERE
        } else {
            // Fallback for older iOS versions.
            UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                return self
            }
            
            context.translateBy(x: 0, y: self.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.setBlendMode(.normal)
            
            let rect = CGRect(origin: .zero, size: self.size)
            context.clip(to: rect, mask: self.cgImage!)
            color.setFill()
            context.fill(rect)
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // The image created this way is already "original", but it doesn't hurt to be explicit.
            return newImage?.withRenderingMode(.alwaysOriginal) ?? self // <-- AND HERE FOR CONSISTENCY
        }
    }
}
