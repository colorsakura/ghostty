import OSLog
import SwiftUI
import GhosttyKit

/// A surface is terminology in Ghostty for a terminal surface, or a place where a terminal is actually drawn
/// and interacted with. The word "surface" is used because a surface may represent a window, a tab,
/// a split, a small preview pane, etc. It is ANYTHING that has a terminal drawn to it.
///
/// We just wrap an AppKit NSView here at the moment so that we can behave as low level as possible
/// since that is what the Metal renderer in Ghostty expects. In the future, it may make more sense to
/// wrap an MTKView and use that, but for legacy reasons we didn't do that to begin with.
struct TerminalSurfaceView: NSViewRepresentable {
    @StateObject private var state: TerminalSurfaceView_Real
    
    init(app: ghostty_app_t) {
        self._state = StateObject(wrappedValue: TerminalSurfaceView_Real(app))
    }
    
    func makeNSView(context: Context) -> TerminalSurfaceView_Real {
        // We need the view as part of the state to be created previously because
        // the view is sent to the Ghostty API so that it can manipulate it
        // directly since we draw on a render thread.
        return state;
    }
    
    func updateNSView(_ view: TerminalSurfaceView_Real, context: Context) {
        // Nothing we need to do here.
    }
}

// The actual NSView implementation for the terminal surface.
class TerminalSurfaceView_Real: NSView, ObservableObject {
    // We need to support being a first responder so that we can get input events
    override var acceptsFirstResponder: Bool { return true }
    
    private var surface: ghostty_surface_t? = nil
    private var error: Error? = nil
    
    init(_ app: ghostty_app_t) {
        // Initialize with some default frame size. The important thing is that this
        // is non-zero so that our layer bounds are non-zero so that our renderer
        // can do SOMETHING.
        super.init(frame: NSMakeRect(0, 0, 800, 600))
        
        // Setup our surface. This will also initialize all the terminal IO.
        var surface_cfg = ghostty_surface_config_s(
            nsview: Unmanaged.passUnretained(self).toOpaque(),
            scale_factor: 1.0)
        guard let surface = ghostty_surface_new(app, &surface_cfg) else {
            self.error = AppError.surfaceCreateError
            return
        }
        
        self.surface = surface;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for this view")
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        
        if let surface = self.surface {
            ghostty_surface_set_size(surface, UInt32(self.bounds.size.width), UInt32(self.bounds.size.height))
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        print("Mouse down: \(event)")
    }
    
    override func keyDown(with event: NSEvent) {
        print("Key down: \(event)")
    }
}

/*
 struct TerminalSurfaceView_Previews: PreviewProvider {
     static var previews: some View {
         TerminalSurfaceView()
     }
 }
 */
