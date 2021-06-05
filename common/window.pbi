
; handling sdl, window

DeclareModule window
  EnableExplicit
  
  ; initalize sdl, open a window, intialize openGL and set basic settings
  Declare.l init(title.s, width, height, sdl_init.l = SDL::#INIT_VIDEO | sdl::#INIT_EVENTS | sdl::#INIT_TIMER, img_init.l = 0)
  
  ; close the window, opengl and sdl
  Declare quit()
  
  ; swap write & display buffers
  Declare SwapBuffers()
  
  ; poll all events from SDL. 
  Declare.l PollEvents()
  
  ; reformat the sourcefile name to a nice title, need to be called in the main file.
  Declare.s _CreateTitle(str.s)
  Macro CreateTitle()
    window::_CreateTitle(#PB_Compiler_File)
  EndMacro
  
  ; check, if the Program should quit - for example when the user close the window
  Declare.l WindowShouldClose()
  Declare SetWindowShouldClose(state.l)
  
  ; return mouse x and y coordinate in windows-coordinates - updated after PollEvents()
  Declare.l GetMouseX()
  Declare.l GetMouseY()
  
  ; is mousebutton pressed? sdl::#button_left and so on - updated after PollEvents()
  Declare.l GetMouseButton(x.l)
  
  ; is MouseWheel moved? - updated after PollEvents()
  Declare.l GetMouseWheelY()
  
  ; is Keyboard-button pressed - use sdl::#scancode_* constants - updated after PollEvents()
  Declare.l GetKey(scancode.l)
  
  ; return window size and aspect ratio
  Declare.l GetWidth()
  Declare.l GetHeight()
  Declare.f GetAspect()
  
  ; set WindowTitle
  Declare SetTitle(title.s)
  
EndDeclareModule

Module window  
  ; handle every SDL-Event - *userdata is unused
  Declare _WatchEvent(*userdata, *e.sdl::event)
  
  ; update variables and set gl::viewport
  Declare _UpdateAspectAndViewport()
  
  ;- structures and globals 
  ; simple mapping for scancodes
  Structure sdl_scancodes
    key.a[sdl::#NUM_SCANCODES]
  EndStructure
  Prototype p_function()
  
  ; some variables
  Structure sWindow
    *window.SDL::Window         ; windows created by SDL
    title.s                     ; title of the window
    fps.s                       ; fps text
    *GLContext.SDL::t_GLContext ; our opengl context
    aspect.f                    ; width / height = aspect of the window
    w.l                         ; width of the window
    h.l                         ; height of the window
    UpdateNeeded.l              ; indicates, that the window is moved/resized
    *scan.sdl_scancodes         ; keyboard-handling
    WindowShouldClose.l         ; should quit?
    mousewheel.l                ; mousewheel handling
    mx.l                        ; mouse handling
    my.l
    mbutton.l
  EndStructure
  Global Window.sWindow
  
  Procedure.l init(title.s, width, height, sdl_init.l = SDL::#INIT_VIDEO | sdl::#INIT_EVENTS | sdl::#INIT_TIMER, img_init.l = 0)
    
    If SDL::Init(sdl_init) 
      MessageRequester(title, "Can't init SDL2" + #LF$ + sdl::GetError())
      ProcedureReturn #False
    EndIf
    
    CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
      If (sdl::IMG_Init(img_init) & img_init) <> img_init
        MessageRequester(title, "Can't init SDL2_image" + #LF$ + sdl::IMG_GetError())
        sdl::Quit()
        ProcedureReturn #False
      EndIf
    CompilerEndIf
    
    ; 4x multisampling for antialiasing
    sdl::GL_SetAttribute(sdl::#GL_MULTISAMPLEBUFFERS,1) 
    sdl::GL_SetAttribute(sdl::#GL_MULTISAMPLESAMPLES,4) 
    
    ; We don't want the core profile
    SDL::GL_SetAttribute(SDL::#GL_CONTEXT_PROFILE_MASK, SDL::#GL_CONTEXT_PROFILE_CORE)
    
    ; higher depth filter
    sdl::GL_SetAttribute(sdl::#GL_DEPTH_SIZE,24)
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      ; To make MacOS happy; should not be needed
      sdl::GL_SetAttribute(sdl::#GL_CONTEXT_FLAGS, sdl::#GL_CONTEXT_FORWARD_COMPATIBLE_FLAG)
    CompilerEndIf
    
    ; open a resizeable window for open gl output
    Window\window = SDL::CreateWindow(title, SDL::#WINDOWPOS_UNDEFINED, SDL::#WINDOWPOS_UNDEFINED, width, height, SDL::#WINDOW_OPENGL | SDL::#WINDOW_ALLOW_HIGHDPI | SDL::#WINDOW_RESIZABLE)
    If Window\window = #Null
      MessageRequester(title, "Can't open Window" + #LF$ + sdl::GetError())
      quit()
      ProcedureReturn #False
    EndIf
    
    Window\title = title
    
    ; Callback for events
    sdl::AddEventWatch(@_WatchEvent(), #Null)  
    
    ; create a gl-context
    Window\GLContext = SDL::GL_CreateContext(Window\window)
    If Window\GLContext = #Null
      MessageRequester(title, "Can't create gl-Context" + #LF$ + sdl::GetError())
      quit()
      ProcedureReturn #False
    EndIf
    
    ; set vsync: 0 off, 1 on, -1 adaptive vsync
    SDL::GL_SetSwapInterval( 0 )
    
    ; load all OpenGL function pointers
    If gl::Init() = #False
      MessageRequester(title, "Can't initalize OpenGL")
      quit()
      ProcedureReturn #False
    EndIf
    
    _UpdateAspectAndViewport()
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure quit()
    gl::Quit()
    
    If Window\GLContext
      sdl::GL_DeleteContext(Window\GLContext)
      Window\GLContext = #Null
    EndIf    
    
    If Window\window 
      sdl::DestroyWindow(Window\window)
      Window\window = #Null
    EndIf
    
    CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
      sdl::IMG_Quit()
    CompilerEndIf
    
    sdl::Quit()
  EndProcedure
  
  Procedure _WatchEvent(*userdata, *e.sdl::event)
    Select *e\type
      Case sdl::#quit
        Window\WindowShouldClose=#True
        
      Case sdl::#WINDOWEVENT
        Select *e\window\event
          Case sdl::#WINDOWEVENT_RESIZED, sdl::#WINDOWEVENT_MOVED
            Window\UpdateNeeded = #True
            
        EndSelect  
      Case sdl::#MOUSEWHEEL
        Window\mousewheel + *e\wheel\y
    EndSelect
    
  EndProcedure
  
  Procedure SwapBuffers()
    SDL::GL_SwapWindow(window\window)
  EndProcedure
    
  Procedure.l PollEvents()
    Protected.l res = #False
    
    ; reset mousewheel
    Window\mousewheel = 0
    
    ; Show FPS
    Static.sdl::ext_Timer fps_timer ; a new timer
    Static.d fpstime                ;    time passed
    Static.l fpsframes              ;  frames rendered
    
    fpsframes +1
    fpstime + sdl::ext_DeltaSeconds(fps_timer,1000); returns seconds since last call - clamp to 1/15 s max
    
    If fpsframes > 1000 Or fpstime > 1; when one second passed or 1000 frames are rendered, update window-title
      window\fps = " - "+
                   StrF(fpsframes / fpstime, 2) +" fps "+
                   StrF(fpstime / fpsframes * 1000.0,2)+" ms"
      
      sdl::SetWindowTitle(Window\window, Window\title + window\fps)
      fpsframes = 0
      fpstime = 0
    EndIf
    
    ; read all evnts - _watchEvent is called for every event
    sdl::PumpEvents()
    
    ; window moved/resized?
    If Window\UpdateNeeded 
      _UpdateAspectAndViewport()
      Window\UpdateNeeded  = #False
      res = #True
    EndIf
    
    ; get keyboard-status-array
    Window\scan = sdl::GetKeyboardState(#Null)
    
    ; get mouse data
    Window\mbutton = sdl::GetMouseState(@Window\mx, @Window\my)
    
    ProcedureReturn res
  EndProcedure
  
  Procedure.s _CreateTitle(str.s)
    Protected.l pos = CountString(str, #PS$)
    Protected.s first = StringField(str, pos -1,#PS$)
    Protected.s nb = StringField(first, 1,".")
    first=ReplaceString(StringField(first,2,"."),"_"," ")
    Protected.s chapter = StringField(first,2,".")
    
    Protected.s second = StringField(str, pos, #PS$)
    If CountString(second,".") = 2
      nb+"."+ StringField(Second,1,".") + "." + StringField(Second,2,".")
      second = StringField(second,3,".")
    Else
      nb+"."+ StringField(Second,1,".") 
      second = StringField(second,2,".")
    EndIf
    Protected.s file = GetFilePart( str, #PB_FileSystem_NoExtension )
    file = ReplaceString(file,"_", " ")
    
    ProcedureReturn nb+" "+first+" - "+file  
  EndProcedure
  
  Procedure SetWindowShouldClose(state.l)
    Window\WindowShouldClose = state
  EndProcedure
  
  Procedure.l WindowShouldClose()
    ProcedureReturn Window\WindowShouldClose
  EndProcedure
  
  Procedure.l GetMouseX()
    ProcedureReturn Window\mx
  EndProcedure
  
  Procedure.l GetMouseY()
    ProcedureReturn Window\my
  EndProcedure
  
  Procedure.l GetMouseButton(x.l)
    ProcedureReturn Bool( Window\mbutton & sdl::BUTTON(x) )
  EndProcedure
  
  Procedure.l GetMouseWheelY()
    ProcedureReturn Window\mousewheel
  EndProcedure
  
  Procedure.l GetKey(scancode.l)
    If Window\scan
      ProcedureReturn Window\scan\key[scancode]
    EndIf
  EndProcedure
  
  Procedure.l GetWidth()
    ProcedureReturn window\w
  EndProcedure
  
  Procedure.l GetHeight()
    ProcedureReturn window\h
  EndProcedure
  
  Procedure.f GetAspect()
    ProcedureReturn window\aspect
  EndProcedure
  
  Procedure _UpdateAspectAndViewport()
    ; get size
    sdl::GL_GetDrawableSize(Window\window, @Window\w, @Window\h)
    
    ; set viewport
    gl::Viewport(0,0,Window\w,Window\h)
    
    ; update aspect
    Window\aspect = Window\w / Window\h   
  EndProcedure 
  
  Procedure SetTitle(title.s)
    window\title = title
    sdl::SetWindowTitle(window\window, title + window\fps)
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 203
; FirstLine = 185
; Folding = -----
; EnableXP