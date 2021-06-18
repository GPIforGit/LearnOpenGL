EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Depth-testing

; note:
; Remember the loadTexture() function is in our example in the texture-module

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
XIncludeFile "../../../common/texture.pbi"
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
  gl::DepthFunc(GL::#ALWAYS);  always pass the depth test (same effect as gl::Disable(GL::#DEPTH_TEST))
  
  ; build and compile shaders
  ; -------------------------
  Protected.l Shader = shader::new("depth_testing.vs", "depth_testing.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    cubeVertices:
    ;      positions          texture coords
    Data.f -0.5, -0.5, -0.5,  0.0, 0.0, ;1
           0.5, -0.5, -0.5,  1.0, 0.0,
           0.5,  0.5, -0.5,  1.0, 1.0,
           0.5,  0.5, -0.5,  1.0, 1.0,
           -0.5,  0.5, -0.5,  0.0, 1.0,
           -0.5, -0.5, -0.5,  0.0, 0.0,           
           -0.5, -0.5,  0.5,  0.0, 0.0, ;2
           0.5, -0.5,  0.5,  1.0, 0.0,
           0.5,  0.5,  0.5,  1.0, 1.0,
           0.5,  0.5,  0.5,  1.0, 1.0,
           -0.5,  0.5,  0.5,  0.0, 1.0,
           -0.5, -0.5,  0.5,  0.0, 0.0,
           -0.5,  0.5,  0.5,  1.0, 0.0, ;3
           -0.5,  0.5, -0.5,  1.0, 1.0,
           -0.5, -0.5, -0.5,  0.0, 1.0,
           -0.5, -0.5, -0.5,  0.0, 1.0,
           -0.5, -0.5,  0.5,  0.0, 0.0,
           -0.5,  0.5,  0.5,  1.0, 0.0,
           0.5,  0.5,  0.5,  1.0, 0.0, ;4
           0.5,  0.5, -0.5,  1.0, 1.0,
           0.5, -0.5, -0.5,  0.0, 1.0,
           0.5, -0.5, -0.5,  0.0, 1.0,
           0.5, -0.5,  0.5,  0.0, 0.0,
           0.5,  0.5,  0.5,  1.0, 0.0,
           -0.5, -0.5, -0.5,  0.0, 1.0, ;5
           0.5, -0.5, -0.5,  1.0, 1.0,
           0.5, -0.5,  0.5,  1.0, 0.0,
           0.5, -0.5,  0.5,  1.0, 0.0,
           -0.5, -0.5,  0.5,  0.0, 0.0,
           -0.5, -0.5, -0.5,  0.0, 1.0,
           -0.5,  0.5, -0.5,  0.0, 1.0, ;6
           0.5,  0.5, -0.5,  1.0, 1.0,
           0.5,  0.5,  0.5,  1.0, 0.0,
           0.5,  0.5,  0.5,  1.0, 0.0,
           -0.5,  0.5,  0.5,  0.0, 0.0,
           -0.5,  0.5, -0.5,  0.0, 1.0
    cubeVerticesEnd:
    planeVertices:
    ; positions              texture Coords (note we set these higher than 1 (together With GL::#REPEAT As texture wrapping mode). this will cause the floor texture To Repeat)
    Data.f 5.0, -0.5,  5.0,  2.0, 0.0, ;1
           -5.0, -0.5,  5.0,  0.0, 0.0,
           -5.0, -0.5, -5.0,  0.0, 2.0,
           5.0, -0.5,  5.0,  2.0, 0.0, ;2
           -5.0, -0.5, -5.0,  0.0, 2.0,
           5.0, -0.5, -5.0,  2.0, 2.0								
    planeVerticesEnd:
  EndDataSection
  
  ; cube VAO
  Protected.l cubeVAO, cubeVBO
  gl::GenVertexArrays(1, @cubeVAO)
  gl::GenBuffers(1, @cubeVBO)
  gl::BindVertexArray(cubeVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, cubeVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?cubeVerticesEnd - ?cubeVertices, ?cubeVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(1)
  gl::VertexAttribPointer(1, 2, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 3 * SizeOf(float))
  gl::BindVertexArray(0)
  ; plane VAO
  Protected.l planeVAO, planeVBO
  gl::GenVertexArrays(1, @planeVAO)
  gl::GenBuffers(1, @planeVBO)
  gl::BindVertexArray(planeVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, planeVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?planeVerticesEnd - ?planeVertices, ?planeVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(1)
  gl::VertexAttribPointer(1, 2, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 3 * SizeOf(float))
  gl::BindVertexArray(0)
  
  ; load textures
  ; -------------
  Protected.l cubeTexture  = texture::Load("../../../resources/textures/marble.jpg")
  Protected.l floorTexture = texture::load("../../../resources/textures/metal.png")
  
  ; shader configuration
  ; --------------------
  shader::use(shader)
  shader::setInt(shader,"texture1", 0)
  
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
    
    shader::use(shader)
    Protected.math::mat4x4 model, *view, projection
    math::Mat4x4_set_Scalar(model, 1)
    *view = camera::GetViewMatrix(*camera)
    math::perspective(projection, Radian(camera::GetZoom(*camera)), window::GetAspect(), 0.1, 100.0)
    shader::setMat4x4(shader, "view", *view)
    shader::setMat4x4(shader, "projection", projection)
    ; cubes
    gl::BindVertexArray(cubeVAO)
    gl::ActiveTexture(GL::#TEXTURE0)
    gl::BindTexture(GL::#TEXTURE_2D, cubeTexture) 	
    math::translate_float(model, model, -1.0, 0.0, -1.0)
    shader::setMat4x4(shader, "model", model)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    math::Mat4x4_set_Scalar(model,1)
    math::translate_float(model, model, 2.0, 0.0, 0.0)
    shader::setMat4x4(shader, "model", model)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    ; floor
    gl::BindVertexArray(planeVAO)
    gl::BindTexture(GL::#TEXTURE_2D, floorTexture)
    shader::setMat4x4(shader,"model", math::m4_1)
    gl::DrawArrays(GL::#TRIANGLES, 0, 6)
    gl::BindVertexArray(0)    
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @cubeVAO)
  gl::DeleteVertexArrays(1, @planeVAO)
  gl::DeleteBuffers(1, @cubeVBO)
  gl::DeleteBuffers(1, @planeVBO)
  
  texture::Delete(floorTexture)
  texture::delete(cubeTexture)
  
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





