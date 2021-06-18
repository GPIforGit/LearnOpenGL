EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Anti-Aliasing

; changes: Press m for enable/disable msaa

DeclareModule SDL_Config
  ;we want OpenGL-Version 3.3
  #GL_MAJOR_VERSION = 3
  #GL_MINOR_VERSION = 3
  ;sdl2_image
  #UseImage = #True
EndDeclareModule

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"
XIncludeFile #PB_Compiler_Home + "Include/sdl2/opengl.pbi"
XIncludeFile #PB_Compiler_Home + "Include/math/math.pbi"
;XIncludeFile #PB_Compiler_Home + "Include/assimp/assimp.pbi"
XIncludeFile "../../../common/shaders.pbi"
XIncludeFile "../../../common/camera.pbi"
XIncludeFile "../../../common/window.pbi"
;XIncludeFile "../../../common/texture.pbi"
;XIncludeFile "../../../common/model.pbi"

Declare processInput()

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

; camera
Global *camera = camera::new_float(0,0,3)
Global.f lastX =  #SCR_WIDTH / 2.0
Global.f lastY = #SCR_HEIGHT / 2.0
Global.l firstMouse = #True

; timing
Global.sdl::Ext_timer Delta_Timer
Global.d deltaTime

Procedure main()
  ; initialize, configure and window creation
  ; -----------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH,#SCR_HEIGHT, sdl::#INIT_VIDEO | sdl::#INIT_EVENTS | sdl::#INIT_TIMER, sdl::#IMG_INIT_JPG | sdl::#IMG_INIT_PNG)
    End
  EndIf
  
  ; configure global opengl state
  ; -----------------------------
  gl::Enable(GL::#DEPTH_TEST)
  ;gl::enable(gl::#CULL_FACE)
  gl::Disable(GL::#MULTISAMPLE)

  
  ; build and compile shaders
  ; -------------------------
  Protected.l Shader = shader::new("anti_aliasing.vs", "anti_aliasing.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    cubeVertices:
    ; positions       
    Data.f -0.5, -0.5, -0.5, ;1
           0.5, -0.5, -0.5,
           0.5,  0.5, -0.5,
           0.5,  0.5, -0.5,
           -0.5,  0.5, -0.5,
           -0.5, -0.5, -0.5,
           -0.5, -0.5,  0.5, ;2
           0.5, -0.5,  0.5,
           0.5,  0.5,  0.5,
           0.5,  0.5,  0.5,
           -0.5,  0.5,  0.5,
           -0.5, -0.5,  0.5,
           -0.5,  0.5,  0.5, ;3
           -0.5,  0.5, -0.5,
           -0.5, -0.5, -0.5,
           -0.5, -0.5, -0.5,
           -0.5, -0.5,  0.5,
           -0.5,  0.5,  0.5,
           0.5,  0.5,  0.5, ;4
           0.5,  0.5, -0.5,
           0.5, -0.5, -0.5,
           0.5, -0.5, -0.5,
           0.5, -0.5,  0.5,
           0.5,  0.5,  0.5,
           -0.5, -0.5, -0.5, ;5
           0.5, -0.5, -0.5,
           0.5, -0.5,  0.5,
           0.5, -0.5,  0.5,
           -0.5, -0.5,  0.5,
           -0.5, -0.5, -0.5,
           -0.5,  0.5, -0.5, ;6
           0.5,  0.5, -0.5,
           0.5,  0.5,  0.5,
           0.5,  0.5,  0.5,
           -0.5,  0.5,  0.5,
           -0.5,  0.5, -0.5
    cubeVerticesEnd:
  EndDataSection
  
  ; setup cube VAO
  Protected.l cubeVAO, cubeVBO
  gl::GenVertexArrays(1, @cubeVAO)
  gl::GenBuffers(1, @cubeVBO)
  gl::BindVertexArray(cubeVAO);
  gl::BindBuffer(GL::#ARRAY_BUFFER, cubeVBO);
  gl::BufferData(GL::#ARRAY_BUFFER, ?cubeVerticesEnd - ?cubeVertices, ?cubeVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 3 * SizeOf(float), 0)
  
  ;- render loop  
  ;  -----------
  While Not window::ShouldClose()
    
    ; per-frame time logic (limited to 1/15 seconds)
    ; ----------------------------------------------
    deltaTime = sdl::ext_DeltaSeconds(delta_Timer)
    
    ; input
    ; -----
    processInput()
    
    ; window size changed
    ; -------------------
    If window::HasResized()
      gl::Viewport(0,0, window::GetWidth(), window::GetHeight())                  
    EndIf
    
    ; render
    ; ------
    
    gl::ClearColor(0.1, 0.1, 0.1, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    
    ; set transformation matrices		
    shader::use(shader)
    Protected.math::mat4x4 projection
    math::perspective(projection, Radian(camera::GetZoom(*camera)), window::GetAspect(), 0.1, 1000.0)
    shader::setMat4x4(shader, "projection", projection)
    shader::setMat4x4(shader, "view", camera::GetViewMatrix(*camera))
    shader::setMat4x4(shader, "model", math::m4_1)
    
    gl::BindVertexArray(cubeVAO)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  
  gl::DeleteVertexArrays(1, @cubeVAO)
  gl::DeleteBuffers(1, @cubeVBO)
  
  shader::Delete(Shader)  
  
  camera::delete(*camera):*camera = #Null
  
  ; terminate, clearing all previously allocated resources
  ; ------------------------------------------------------
  window::quit()
EndProcedure
main()

; process all input: query whether relevant keys are pressed/released this frame and react accordingly
; ----------------------------------------------------------------------------------------------------
Procedure processInput()
  If window::GetKey( sdl::#SCANCODE_ESCAPE )
    window::SetShouldClose( #True )
  EndIf   
  
  Static.l pressedM
  If window::GetKey(sdl::#SCANCODE_M)
    If Not pressedM
      pressedM = #True
      If gl::IsEnabled (gl::#MULTISAMPLE)        
        gl::Disable(gl::#MULTISAMPLE)
      Else
        gl::Enable(gl::#MULTISAMPLE)
      EndIf
    EndIf
  Else
    pressedM = #False
  EndIf
  
  
  Protected.f cameraSpeed = 2.5 * deltaTime 
  Protected.math::vec3 tmp
  
  If window::GetKey(sdl::#scancode_w)
    camera::ProcessKeyboard(*camera, camera::#FORWARD, cameraSpeed)    
  EndIf
  If window::GetKey(sdl::#scancode_s)
    camera::ProcessKeyboard(*camera, camera::#BACKWARD, cameraSpeed)
  EndIf
  If window::GetKey(sdl::#scancode_a)    
    camera::ProcessKeyboard(*camera, camera::#LEFT, cameraSpeed)
  EndIf
  If window::GetKey(sdl::#scancode_d)    
    camera::ProcessKeyboard(*camera, camera::#RIGHT, cameraSpeed)
  EndIf
  If window::GetKey(sdl::#scancode_q)    
    camera::ProcessKeyboard(*camera, camera::#UP, cameraSpeed)
  EndIf
  If window::GetKey(sdl::#scancode_e)    
    camera::ProcessKeyboard(*camera, camera::#DOWN, cameraSpeed)
  EndIf
  
  Protected.l xpos, ypos
  xpos = window::GetMouseX()
  ypos = window::GetMouseY()  
  
  If window::GetMouseButton( sdl::#BUTTON_RIGHT )
    If firstMouse
      ; start relative
      lastX = xpos
      lastY = ypos      
      firstMouse = #False
    ElseIf xpos<>lastX Or ypos<>lastY
      ; only changes when moved!
      Protected.f xoffset = xpos - lastX
      Protected.f yoffset = lastY - ypos;  reversed since y-coordinates go from bottom to top
      
      lastX = xpos
      lastY = ypos
      
      camera::ProcessMouseMovement(*camera, xoffset, yoffset)
      
    EndIf
  Else
    firstMouse = #True ; restart relative
  EndIf
  
  If window::GetMouseWheelY()
    camera::ProcessMouseScroll( *camera, window::GetMouseWheelY() )
  EndIf
  
  
EndProcedure





