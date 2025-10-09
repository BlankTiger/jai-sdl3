#run build();

build :: () {

    set_build_options_dc(.{do_output=false});

    options := get_build_options();

    if !generate_bindings() {
        compiler_set_workspace_status(.FAILED);
        return;
    }
}

generate_bindings :: () -> bool {

    output_filename: string;
    opts: Generate_Bindings_Options;

    {
        opts.header = HEADER;

        #if OS == .WINDOWS {

            output_filename = "windows/windows.jai";
            opts.strip_flags = .FUNCTIONS_WITH_VALIST;

            FOOTER :: #string EOF
#if CPU == .X64 {
    sdl3 :: #library,no_dll "bin/x64/SDL3";
} else #if CPU == .ARM64 {
    sdl3 :: #library,no_dll "bin/arm64/SDL3";
}
EOF
            // DLL provided by user not in bin, so use our own footer not generated library declaration
            opts.footer = FOOTER;
            opts.generate_library_declarations = false;

            #if CPU == .X64 {
                array_add(*opts.library_search_paths, "windows/bin/x64");
            } else #if CPU == .ARM64 {
                array_add(*opts.library_search_paths, "windows/bin/arm64");
            } else {
                assert(false, "the CPU % is currently unsupported. You might be able to add support for it though!", CPU);
            }

            array_add(*opts.libraries, .{filename="SDL3"});

        } else #if OS == .LINUX {
            opts.strip_flags = .FUNCTIONS_WITH_VALIST;

            output_filename = "linux/linux.jai";

            FOOTER :: #string EOF
libsdl3 :: #library,system "libSDL3.so.0";
EOF;
            opts.footer = FOOTER;
            opts.generate_library_declarations = false;

            array_add(*opts.libraries, .{filename="libSDL3.so.0"});

        } else #if OS == .MACOS {

            output_filename = "macos/macos.jai";
            opts.strip_flags = .FUNCTIONS_WITH_VALIST;

            FOOTER :: #string EOF
#if CPU == .X64 {
    libsdl3 :: #library "bin/x64/libSDL3.0_dynamic";
} else #if CPU == .ARM64 {
    libsdl3 :: #library "bin/arm64/libSDL3.0_dynamic";
}
EOF;
            #if CPU == .X64 {
                array_add(*opts.library_search_paths, "macos/bin/x64");
            } else #if CPU == .ARM64 {
                array_add(*opts.library_search_paths, "macos/bin/arm64");
            } else {
                assert(false, "the CPU % is currently unsupported. You might be able to add support for it though!", CPU);
            }

            opts.footer = FOOTER;
            opts.generate_library_declarations = false;

            // We need the .a to bind but .dylib is used in runtime.
            array_add(*opts.libraries, .{filename="libSDL3.0"});
        } else {
            assert(false, "the OS % is currently unsupported. You might be able to add support for it though!", OS);
        }

        array_add(*opts.include_paths, "include");
        array_add(*opts.source_files, "include/SDL3/SDL.h");

        array_add(*opts.strip_prefixes, "SDL_");

        opts.alias_original_enum_names = false;

        opts.visitor = sdl3_visitor;
        opts.generate_compile_time_struct_checks = false;
    }

    return generate_bindings(opts, output_filename);
}

sdl3_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {

    if parent_decl return .RECURSE;

    if array_find(DECLARATIONS_TO_OMIT, decl.name) {
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }

    return .RECURSE;
}

#scope_file

#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Check";
#import "Bindings_Generator";
#import "File";

DECLARATIONS_TO_OMIT :: string.[
    "_m_prefetch",
    "__debugbreak",

    /*
    Those are force inlined functions defined in the headers, so they don't appear in the library and so bindings generator complains.

    One way is to automatically remove inline, compile them into a DLL, and turn them into #c_call jai procs. However, this loses inline.

    The performant way is to rewrite them in pure jai code, however that introduces overhead of ensuring they are updated.
    */
    "SDL_size_mul_check_overflow",
    "SDL_size_mul_check_overflow_builtin",
    "SDL_size_add_check_overflow",
    "SDL_size_add_check_overflow_builtin",
    "SDL_SwapFloat",
    "SDL_MostSignificantBitIndex32",
    "SDL_HasExactlyOneBitSet32",
    "SDL_RectToFRect",
    "SDL_PointInRect",
    "SDL_RectEmpty",
    "SDL_RectsEqual",
    "SDL_PointInRectFloat",
    "SDL_RectEmptyFloat",
    "SDL_RectsEqualEpsilon",
    "SDL_RectsEqualFloat",

    "SDL_WindowFlags",

    "SDL_InitFlags",
    "SDL_INIT_AUDIO",
    "SDL_INIT_VIDEO",
    "SDL_INIT_JOYSTICK",
    "SDL_INIT_HAPTIC",
    "SDL_INIT_GAMEPAD",
    "SDL_INIT_EVENTS",
    "SDL_INIT_SENSOR",
    "SDL_INIT_CAMERA",

    "SDL_GPUTextureUsageFlags",
    "SDL_GPU_TEXTUREUSAGE_SAMPLER",
    "SDL_GPU_TEXTUREUSAGE_COLOR_TARGET",
    "SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET",
    "SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ",
    "SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ",
    "SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE",
    "SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE",


    "SDL_GPUBufferUsageFlags",
    "SDL_GPU_BUFFERUSAGE_VERTEX",
    "SDL_GPU_BUFFERUSAGE_INDEX",
    "SDL_GPU_BUFFERUSAGE_INDIRECT",
    "SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ",
    "SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ",
    "SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE",

    "SDL_GPUShaderFormat",
    "SDL_GPU_SHADERFORMAT_INVALID",
    "SDL_GPU_SHADERFORMAT_PRIVATE",
    "SDL_GPU_SHADERFORMAT_SPIRV",
    "SDL_GPU_SHADERFORMAT_DXBC",
    "SDL_GPU_SHADERFORMAT_DXIL",
    "SDL_GPU_SHADERFORMAT_MSL",
    "SDL_GPU_SHADERFORMAT_METALLIB",

    "SDL_malloc_func",
    "SDL_calloc_func",
    "SDL_realloc_func",
    "SDL_free_func",

    "SDL_LogOutputFunction",

    "SDL_Event",

    "SDL_MouseButtonFlags",
    "SDL_BUTTON_LEFT",
    "SDL_BUTTON_MIDDLE",
    "SDL_BUTTON_RIGHT",
    "SDL_BUTTON_X1",
    "SDL_BUTTON_X2",

    "SDL_abs",
    "SDL_isnan",
    "SDL_isinf",
    "SDL_tan",
    "SDL_acos",
    "SDL_sin",
    "SDL_cos",
    "SDL_atan",
    "SDL_asin",
    "SDL_sqrt",
    "SDL_pow",
    "SDL_exp",
    "SDL_log",
    "SDL_ceil",
    "SDL_floor",
    "SDL_atan2",

    "SDL_free",
];

/*
The header contains things not yet supported by bindings generator like the SDL_WindowFlags set of enums, as they use macros calling system macros.

These should rarely changed, but last checked for SDL 3.2.14
*/
HEADER :: #string EOF

/**
* A bitmask of pressed mouse buttons, as reported by SDL_GetMouseState, etc.
*
* - Button 1: Left mouse button
* - Button 2: Middle mouse button
* - Button 3: Right mouse button
* - Button 4: Side mouse button 1
* - Button 5: Side mouse button 2
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_GetMouseState
* \sa SDL_GetGlobalMouseState
* \sa SDL_GetRelativeMouseState
*/
MouseButtonFlags :: enum_flags u32 {
    LEFT   :: 1;
    MIDDLE :: 2;
    RIGHT  :: 3;
    X1     :: 4;
    X2     :: 5;
}

/**
* The structure for all events in SDL.
*
* The SDL_Event structure is the core of all event handling in SDL. SDL_Event
* is a union of all event structures used in SDL.
*
* \since This struct is available since SDL 3.2.0.
*/
Event :: union {
    type:            EventType; /**< Event type, shared with all events, Uint32 to cover user events which are not in the SDL_EventType enumeration */
    common:          CommonEvent; /**< Common event data */
    display:         DisplayEvent; /**< Display event data */
    window:          WindowEvent; /**< Window event data */
    kdevice:         KeyboardDeviceEvent; /**< Keyboard device change event data */
    key:             KeyboardEvent; /**< Keyboard event data */
    edit:            TextEditingEvent; /**< Text editing event data */
    edit_candidates: TextEditingCandidatesEvent; /**< Text editing candidates event data */
    text:            TextInputEvent; /**< Text input event data */
    mdevice:         MouseDeviceEvent; /**< Mouse device change event data */
    motion:          MouseMotionEvent; /**< Mouse motion event data */
    button:          MouseButtonEvent; /**< Mouse button event data */
    wheel:           MouseWheelEvent; /**< Mouse wheel event data */
    jdevice:         JoyDeviceEvent; /**< Joystick device change event data */
    jaxis:           JoyAxisEvent; /**< Joystick axis event data */
    jball:           JoyBallEvent; /**< Joystick ball event data */
    jhat:            JoyHatEvent; /**< Joystick hat event data */
    jbutton:         JoyButtonEvent; /**< Joystick button event data */
    jbattery:        JoyBatteryEvent; /**< Joystick battery event data */
    gdevice:         GamepadDeviceEvent; /**< Gamepad device event data */
    gaxis:           GamepadAxisEvent; /**< Gamepad axis event data */
    gbutton:         GamepadButtonEvent; /**< Gamepad button event data */
    gtouchpad:       GamepadTouchpadEvent; /**< Gamepad touchpad event data */
    gsensor:         GamepadSensorEvent; /**< Gamepad sensor event data */
    adevice:         AudioDeviceEvent; /**< Audio device event data */
    cdevice:         CameraDeviceEvent; /**< Camera device event data */
    sensor:          SensorEvent; /**< Sensor event data */
    quit:            QuitEvent; /**< Quit request event data */
    user:            UserEvent; /**< Custom event data */
    tfinger:         TouchFingerEvent; /**< Touch finger event data */
    pproximity:      PenProximityEvent; /**< Pen proximity event data */
    ptouch:          PenTouchEvent; /**< Pen tip touching event data */
    pmotion:         PenMotionEvent; /**< Pen motion event data */
    pbutton:         PenButtonEvent; /**< Pen button event data */
    paxis:           PenAxisEvent; /**< Pen axis event data */
    render:          RenderEvent; /**< Render event data */
    drop:            DropEvent; /**< Drag and drop event data */
    clipboard:       ClipboardEvent; /**< Clipboard event data */

    /* This is necessary for ABI compatibility between Visual C++ and GCC.
    Visual C++ will respect the push pack pragma and use 52 bytes (size of
    SDL_TextEditingEvent, the largest structure for 32-bit and 64-bit
    architectures) for this union, and GCC will use the alignment of the
    largest datatype within the union, which is 8 bytes on 64-bit
    architectures.
    
    So... we'll add padding to force the size to be the same for both.
    
    On architectures where pointers are 16 bytes, this needs rounding up to
    the next multiple of 16, 64, and on architectures where pointers are
    even larger the size of SDL_UserEvent will dominate as being 3 pointers.
    */
    padding:         [128] Uint8;
}

/**
* The prototype for the log output callback function.
*
* This function is called by SDL when there is new text to be logged. A mutex
* is held so that this function is never called by more than one thread at
* once.
*
* \param userdata what was passed as `userdata` to
*                 SDL_SetLogOutputFunction().
* \param category the category of the message.
* \param priority the priority of the message.
* \param message the message being output.
*
* \since This datatype is available since SDL 3.2.0.
*/
LogOutputFunction :: #type (userdata: *void, category: LogCategory, priority: LogPriority, message: *u8) -> void #c_call;

GPUShaderFormat :: enum u32 {
    INVALID  :: 0;
    PRIVATE  :: 1 << 0;
    SPIRV    :: 1 << 1;
    DXBC     :: 1 << 2;
    DXIL     :: 1 << 3;
    MSL      :: 1 << 4;
    METALLIB :: 1 << 5;
}

GPUBufferUsageFlags :: enum_flags u32 {
    VERTEX                :: 1 << 0;
    INDEX                 :: 1 << 1;
    INDIRECT              :: 1 << 2;
    GRAPHICS_STORAGE_READ :: 1 << 3;
    COMPUTE_STORAGE_READ  :: 1 << 4;
    COMPUTE_STORAGE_WRITE :: 1 << 5;
}

/**
* A callback used to implement SDL_malloc().
*
* SDL will always ensure that the passed `size` is greater than 0.
*
* \param size the size to allocate.
* \returns a pointer to the allocated memory, or NULL if allocation failed.
*
* \threadsafety It should be safe to call this callback from any thread.
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_malloc
* \sa SDL_GetOriginalMemoryFunctions
* \sa SDL_GetMemoryFunctions
* \sa SDL_SetMemoryFunctions
*/
malloc_func_type :: #type (size: u64) -> *void #c_call;

/**
* A callback used to implement SDL_calloc().
*
* SDL will always ensure that the passed `nmemb` and `size` are both greater
* than 0.
*
* \param nmemb the number of elements in the array.
* \param size the size of each element of the array.
* \returns a pointer to the allocated array, or NULL if allocation failed.
*
* \threadsafety It should be safe to call this callback from any thread.
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_calloc
* \sa SDL_GetOriginalMemoryFunctions
* \sa SDL_GetMemoryFunctions
* \sa SDL_SetMemoryFunctions
*/
calloc_func_type :: #type (nmemb: u64, size: u64) -> *void #c_call;

/**
* A callback used to implement SDL_realloc().
*
* SDL will always ensure that the passed `size` is greater than 0.
*
* \param mem a pointer to allocated memory to reallocate, or NULL.
* \param size the new size of the memory.
* \returns a pointer to the newly allocated memory, or NULL if allocation
*          failed.
*
* \threadsafety It should be safe to call this callback from any thread.
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_realloc
* \sa SDL_GetOriginalMemoryFunctions
* \sa SDL_GetMemoryFunctions
* \sa SDL_SetMemoryFunctions
*/
realloc_func_type :: #type (mem: *void, size: u64) -> *void #c_call;

/**
* A callback used to implement SDL_free().
*
* SDL will always ensure that the passed `mem` is a non-NULL pointer.
*
* \param mem a pointer to allocated memory.
*
* \threadsafety It should be safe to call this callback from any thread.
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_free
* \sa SDL_GetOriginalMemoryFunctions
* \sa SDL_GetMemoryFunctions
* \sa SDL_SetMemoryFunctions
*/
free_func_type :: #type (mem: *void) -> void #c_call;

/**
* Specifies how a texture is intended to be used by the client.
*
* A texture must have at least one usage flag. Note that some usage flag
* combinations are invalid.
*
* With regards to compute storage usage, READ | WRITE means that you can have
* shader A that only writes into the texture and shader B that only reads
* from the texture and bind the same texture to either shader respectively.
* SIMULTANEOUS means that you can do reads and writes within the same shader
* or compute pass. It also implies that atomic ops can be used, since those
* are read-modify-write operations. If you use SIMULTANEOUS, you are
* responsible for avoiding data races, as there is no data synchronization
* within a compute pass. Note that SIMULTANEOUS usage is only supported by a
* limited number of texture formats.
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_CreateGPUTexture
*/
GPUTextureUsageFlags :: enum_flags u32 {
    SAMPLER :: 1 << 0;
    COLOR_TARGET :: 1 << 1;
    DEPTH_STENCIL_TARGET :: 1 << 2;
    GRAPHICS_STORAGE_READ :: 1 << 3;
    COMPUTE_STORAGE_READ :: 1 << 4;
    COMPUTE_STORAGE_WRITE :: 1 << 5;
    COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE :: 1 << 6;
}

InitFlags :: enum_flags u32 {
    AUDIO    :: 0x00000010;
    VIDEO    :: 0x00000020;
    JOYSTICK :: 0x00000200;
    HAPTIC   :: 0x00001000;
    GAMEPAD  :: 0x00002000;
    EVENTS   :: 0x00004000;
    SENSOR   :: 0x00008000;
    CAMERA   :: 0x00010000;
}

/**
* The flags on a window.
*
* These cover a lot of true/false, or on/off, window state. Some of it is
* immutable after being set through SDL_CreateWindow(), some of it can be
* changed on existing windows by the app, and some of it might be altered by
* the user or system outside of the app's control.
*
* \since This datatype is available since SDL 3.2.0.
*
* \sa SDL_GetWindowFlags
*/
WindowFlags :: enum_flags u64 {
    FULLSCREEN          :: 0x0000000000000001; /**< window is in fullscreen mode */
    OPENGL              :: 0x0000000000000002; /**< window usable with OpenGL context */
    OCCLUDED            :: 0x0000000000000004; /**< window is occluded */
    HIDDEN              :: 0x0000000000000008; /**< window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible */
    BORDERLESS          :: 0x0000000000000010; /**< no window decoration */
    RESIZABLE           :: 0x0000000000000020; /**< window can be resized */
    MINIMIZED           :: 0x0000000000000040; /**< window is minimized */
    MAXIMIZED           :: 0x0000000000000080; /**< window is maximized */
    MOUSE_GRABBED       :: 0x0000000000000100; /**< window has grabbed mouse input */
    INPUT_FOCUS         :: 0x0000000000000200; /**< window has input focus */
    MOUSE_FOCUS         :: 0x0000000000000400; /**< window has mouse focus */
    EXTERNAL            :: 0x0000000000000800; /**< window not created by SDL */
    MODAL               :: 0x0000000000001000; /**< window is modal */
    HIGH_PIXEL_DENSITY  :: 0x0000000000002000; /**< window uses high pixel density back buffer if possible */
    MOUSE_CAPTURE       :: 0x0000000000004000; /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
    MOUSE_RELATIVE_MODE :: 0x0000000000008000; /**< window has relative mode enabled */
    ALWAYS_ON_TOP       :: 0x0000000000010000; /**< window should always be above others */
    UTILITY             :: 0x0000000000020000; /**< window should be treated as a utility window, not showing in the task bar and window list */
    TOOLTIP             :: 0x0000000000040000; /**< window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window */
    POPUP_MENU          :: 0x0000000000080000; /**< window should be treated as a popup menu, requires a parent window */
    KEYBOARD_GRABBED    :: 0x0000000000100000; /**< window has grabbed keyboard input */
    VULKAN              :: 0x0000000010000000; /**< window usable for Vulkan surface */
    METAL               :: 0x0000000020000000; /**< window usable for Metal view */
    TRANSPARENT         :: 0x0000000040000000; /**< window with transparent buffer */
    NOT_FOCUSABLE       :: 0x0000000080000000; /**< window should not be focusable */
}

/**
 * Used to indicate that you don't care what the window position is.
 *
 * If you _really_ don't care, SDL_WINDOWPOS_UNDEFINED is the same, but always
 * uses the primary display instead of specifying one.
 *
 * \param X the SDL_DisplayID of the display to use.
 *
 * \since This macro is available since SDL 3.2.0.
 */
// Original: #define SDL_WINDOWPOS_UNDEFINED_DISPLAY(X)  (SDL_WINDOWPOS_UNDEFINED_MASK|(X))
WINDOWPOS_UNDEFINED_DISPLAY :: inline (display_id: DisplayID) -> DisplayID {
    return SDL_WINDOWPOS_UNDEFINED_MASK | display_id;
}

/**
 * Used to indicate that you don't care what the window position/display is.
 *
 * This always uses the primary display.
 *
 * \since This macro is available since SDL 3.2.0.
 */
// #define SDL_WINDOWPOS_UNDEFINED         SDL_WINDOWPOS_UNDEFINED_DISPLAY(0)
WINDOWPOS_UNDEFINED :: #bake_arguments WINDOWPOS_UNDEFINED_DISPLAY(display_id = 0);

/**
 * A macro to test if the window position is marked as "undefined."
 *
 * \param X the window position value.
 *
 * \since This macro is available since SDL 3.2.0.
 */
// #define SDL_WINDOWPOS_ISUNDEFINED(X)    (((X)&0xFFFF0000) == SDL_WINDOWPOS_UNDEFINED_MASK)
WINDOWPOS_ISUNDEFINED :: inline (display_id: DisplayID) -> bool {
    return (display_id & 0xFFFF0000) == SDL_WINDOWPOS_UNDEFINED_MASK;
}


/**
 * Used to indicate that the window position should be centered.
 *
 * SDL_WINDOWPOS_CENTERED is the same, but always uses the primary display
 * instead of specifying one.
 *
 * \param X the SDL_DisplayID of the display to use.
 *
 * \since This macro is available since SDL 3.2.0.
 */
// #define SDL_WINDOWPOS_CENTERED_DISPLAY(X)  (SDL_WINDOWPOS_CENTERED_MASK|(X))
WINDOWPOS_CENTERED_DISPLAY :: inline (display_id: DisplayID) -> DisplayID {
    return SDL_WINDOWPOS_CENTERED_MASK | display_id;
}

/**
 * Used to indicate that the window position should be centered.
 *
 * This always uses the primary display.
 *
 * \since This macro is available since SDL 3.2.0.
 */
// #define SDL_WINDOWPOS_CENTERED         SDL_WINDOWPOS_CENTERED_DISPLAY(0)
WINDOWPOS_CENTERED :: #bake_arguments WINDOWPOS_CENTERED_DISPLAY(display_id = 0);

/**
 * A macro to test if the window position is marked as "centered."
 *
 * \param X the window position value.
 *
 * \since This macro is available since SDL 3.2.0.
 */
// #define SDL_WINDOWPOS_ISCENTERED(X)    \
            // (((X)&0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK)
WINDOWPOS_ISCENTERED :: inline (pos: u32) -> bool {
    return (pos & 0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK;
}
EOF
