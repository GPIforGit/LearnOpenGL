EnableExplicit

; https://learnopengl.com/Lighting/Basic-Lighting


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
XIncludeFile "../../../common/shaders.pbi"
XIncludeFile "../../../common/camera.pbi"
XIncludeFile "../../../common/window.pbi"

Declare processInput()

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

; camera
Global *camera = camera::new_float(1,1,5)
Global.f lastX =  #SCR_WIDTH / 2.0
Global.f lastY = #SCR_HEIGHT / 2.0
Global.l firstMouse = #True

; timing
Global.sdl::Ext_timer Delta_Timer
Global.d deltaTime

; lighting
Global.math::vec3 lightPos
math::vec3_set_float(lightPos, 1.2, 1.0, 2.0)

Procedure main()
  ; initialize, configure and window creation
  ; -----------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH,#SCR_HEIGHT, sdl::#INIT_VIDEO | sdl::#INIT_EVENTS | sdl::#INIT_TIMER, sdl::#IMG_INIT_JPG | sdl::#IMG_INIT_PNG)
    End
  EndIf
  
  ; configure global opengl state
  ; -----------------------------
  gl::Enable(GL::#DEPTH_TEST)
  
  ; build and compile our shader program
  ; ------------------------------------
  Protected.l lightingShader = shader::new("basic_lighting.vs", "basic_lighting.fs")
  Protected.l lightCubeShader = shader::new("light_cube.vs", "light_cube.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    vertices:
    ;      positions         
    Data.f -0.5, -0.5, -0.5,  0.0,  0.0, -1.0, ;1
           00.5, -0.5, -0.5,  0.0,  0.0, -1.0,
           00.5,  0.5, -0.5,  0.0,  0.0, -1.0,
           00.5,  0.5, -0.5,  0.0,  0.0, -1.0,
           -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
           -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
           -0.5, -0.5,  0.5,  0.0,  0.0,  1.0, ;2
           00.5, -0.5,  0.5,  0.0,  0.0,  1.0,
           00.5,  0.5,  0.5,  0.0,  0.0,  1.0,
           00.5,  0.5,  0.5,  0.0,  0.0,  1.0,
           -0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
           -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
           -0.5,  0.5,  0.5, -1.0,  0.0,  0.0, ;3
           -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
           -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
           -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
           -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
           -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
           00.5,  0.5,  0.5,  1.0,  0.0,  0.0, ;4
           00.5,  0.5, -0.5,  1.0,  0.0,  0.0,
           00.5, -0.5, -0.5,  1.0,  0.0,  0.0,
           00.5, -0.5, -0.5,  1.0,  0.0,  0.0,
           00.5, -0.5,  0.5,  1.0,  0.0,  0.0,
           00.5,  0.5,  0.5,  1.0,  0.0,  0.0,
           -0.5, -0.5, -0.5,  0.0, -1.0,  0.0, ;5
           00.5, -0.5, -0.5,  0.0, -1.0,  0.0,
           00.5, -0.5,  0.5,  0.0, -1.0,  0.0,
           00.5, -0.5,  0.5,  0.0, -1.0,  0.0,
           -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
           -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
           -0.5,  0.5, -0.5,  0.0,  1.0,  0.0, ;6
           00.5,  0.5, -0.5,  0.0,  1.0,  0.0,
           00.5,  0.5,  0.5,  0.0,  1.0,  0.0,
           00.5,  0.5,  0.5,  0.0,  1.0,  0.0,
           -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
           -0.5,  0.5, -0.5,  0.0,  1.0,  0.0
    vertices_end:   
  EndDataSection
  
  ;first, configure the cube's VAO (and VBO)
  Protected.l VBO, cubeVAO
  gl::GenVertexArrays(1, @cubeVAO)
  gl::GenBuffers(1, @VBO)
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?vertices_end - ?vertices, ?vertices, GL::#STATIC_DRAW)
  
  gl::BindVertexArray(cubeVAO)
  
  ; position attribute
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(0)
  ; normal attribute
  gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 3 * SizeOf(float) )
  gl::EnableVertexAttribArray(1)
  
  ; second, configure the light's VAO (VBO stays the same; the vertices are the same for the light object which is also a 3D cube)
  Protected.l lightCubeVAO
  gl::GenVertexArrays(1, @lightCubeVAO)
  gl::BindVertexArray(lightCubeVAO)
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBO)
  ; note that we update the lamp's position attribute's stride to reflect the updated buffer data
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(0)
  
  ;- render loop  
  ;  -----------
  While Not window::WindowShouldClose()
    
    ; per-frame time logic (limited to 1/15 seconds)
    ; ----------------------------------------------
    deltaTime = sdl::ext_DeltaSeconds(delta_Timer)
    
    ; input
    ; -----
    processInput()
    
    ; render
    ; ------
    
    gl::ClearColor(0.1, 0.1, 0.1, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    
    ; change the light's position values over time (can be done anywhere in the render loop actually, but try to do it at least before using the light source positions)
    ; example 1
    ;lightPos\x = 1.0 + Sin( sdl::ext_GetElapsedSeconds() ) * 2.0
    ;lightPos\y = Sin( sdl::ext_GetElapsedSeconds() / 2.0) * 1.0
    ; example 2
    lightpos\x = Sin( sdl::ext_GetElapsedSeconds() ) * 1.5
    lightpos\z = Cos( sdl::ext_GetElapsedSeconds() ) * 1.5
    lightpos\y = Cos( sdl::ext_GetElapsedSeconds()/2) *1.5 
    
    
    ; be sure to activate shader when setting uniforms/drawing objects
    shader::use(lightingShader)
    shader::setVec3_float(lightingShader, "objectColor", 1.0, 0.5, 0.31)
    shader::setVec3_float(lightingShader, "lightColor",  1.0, 1.0, 1.0)
    shader::setVec3(lightingShader, "lightPos", lightPos)
    shader::setVec3(lightingShader, "viewPos", camera::GetPosition(*camera) )
    
    ; view/projection transformations    
    Protected.math::mat4x4 projection
    math::perspective(projection, Radian(camera::GetZoom(*camera)), window::GetAspect(), 0.1, 100.0)
    
    Protected.math::mat4x4 *view = camera::GetViewMatrix(*camera)
    
    shader::setMat4x4(lightingShader, "projection", projection)
    shader::setMat4x4(lightingShader, "view", *view)
    
    ; world transformation
    Protected.math::mat4x4 model
    math::Mat4x4_set_Scalar(model, 1.0)
    shader::setMat4x4(lightingShader, "model", model)
    
    ; render the cube
    gl::BindVertexArray(cubeVAO)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    
    ; also draw the lamp object
    shader::use(lightCubeShader)
    shader::setMat4x4(lightCubeShader, "projection", projection)
    shader::setMat4x4(lightCubeShader, "view", *view)
    math::Mat4x4_set_Scalar(model, 1)
    math::translate(model, model, lightPos)
    math::scale_float(model, model, 0.2, 0.2, 0.2); a smaller cube
    shader::setMat4x4(lightCubeShader, "model", model)
    
    gl::BindVertexArray(lightCubeVAO)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @cubeVAO)
  gl::DeleteVertexArrays(1, @lightCubeVAO)
  gl::DeleteBuffers(1, @VBO)
  shader::Delete(lightCubeShader)  
  shader::Delete(lightingShader)  
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
    window::SetWindowShouldClose( #True )
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


