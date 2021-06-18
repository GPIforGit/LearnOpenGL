EnableExplicit

; 

; note:
; loadcubemap is located in texture-module and takes a filename with a "*". The star is replaced with right,left,...

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
  
  ; build and compile shaders
  ; -------------------------
  Protected.l Shader = shader::new("cubemaps.vs", "cubemaps.fs")
  Protected.l SkyboxShader = shader::new("skybox.vs","skybox.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    cubeVertices:
    ;         positions           normals
    Data.f    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0, ;1
              0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
              0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
              0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
              -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
              -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
              -0.5, -0.5,  0.5,  0.0,  0.0, 1.0, ;2
              0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
              0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
              0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
              -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
              -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
              -0.5,  0.5,  0.5, -1.0,  0.0,  0.0, ;3
              -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
              -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
              -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
              -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
              -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
              0.5,  0.5,  0.5,  1.0,  0.0,  0.0, ;4
              0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
              0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
              0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
              0.5, -0.5,  0.5,  1.0,  0.0,  0.0,
              0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
              -0.5, -0.5, -0.5,  0.0, -1.0,  0.0, ;5
              0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
              0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
              0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
              -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
              -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
              -0.5,  0.5, -0.5,  0.0,  1.0,  0.0, ;6
              0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
              0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
              0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
              -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
              -0.5,  0.5, -0.5,  0.0,  1.0,  0.0
    cubeVerticesEnd:
    
    skyboxVertices:
    ; positions          
    Data.f -1.0,  1.0, -1.0, ;1
           -1.0, -1.0, -1.0,
           1.0, -1.0, -1.0,
           1.0, -1.0, -1.0,
           1.0,  1.0, -1.0,
           -1.0,  1.0, -1.0,
           -1.0, -1.0,  1.0, ;2
           -1.0, -1.0, -1.0,
           -1.0,  1.0, -1.0,
           -1.0,  1.0, -1.0,
           -1.0,  1.0,  1.0,
           -1.0, -1.0,  1.0,
           1.0, -1.0, -1.0, ;3
           1.0, -1.0,  1.0,
           1.0,  1.0,  1.0,
           1.0,  1.0,  1.0,
           1.0,  1.0, -1.0,
           1.0, -1.0, -1.0,
           -1.0, -1.0,  1.0, ;4
           -1.0,  1.0,  1.0,
           1.0,  1.0,  1.0,
           1.0,  1.0,  1.0,
           1.0, -1.0,  1.0,
           -1.0, -1.0,  1.0,
           -1.0,  1.0, -1.0, ;5
           1.0,  1.0, -1.0,
           1.0,  1.0,  1.0,
           1.0,  1.0,  1.0,
           -1.0,  1.0,  1.0,
           -1.0,  1.0, -1.0,
           -1.0, -1.0, -1.0, ;6
           -1.0, -1.0,  1.0,
           1.0, -1.0, -1.0,
           1.0, -1.0, -1.0,
           -1.0, -1.0,  1.0,
           1.0, -1.0,  1.0
    skyboxVerticesEnd:
    
  EndDataSection
  
  ; cube VAO
  Protected.l cubeVAO, cubeVBO
  gl::GenVertexArrays(1, @cubeVAO)
  gl::GenBuffers(1, @cubeVBO)
  gl::BindVertexArray(cubeVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, cubeVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?cubeVerticesEnd - ?cubeVertices, ?cubeVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(1)
  gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 3 * SizeOf(float))
  gl::BindVertexArray(0)
  ; skybox VAO
  Protected.l skyboxVAO, skyboxVBO
  gl::GenVertexArrays(1, @skyboxVAO)
  gl::GenBuffers(1, @skyboxVBO)
  gl::BindVertexArray(skyboxVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, skyboxVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?skyboxVerticesEnd - ?skyboxVertices, ?skyboxVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)  
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 3 * SizeOf(float), 0)  
  gl::BindVertexArray(0)
   
  ; load textures
  ; -------------
  Protected.l cubemapTexture = texture::LoadCubemap("../../../resources/textures/skybox/*.jpg"); * is replaced with right,left,...
  
  ; shader configuration
  ; --------------------
  shader::use(shader)
  shader::setInt(shader,"skybox", 0)
  
  shader::use(skyboxShader)
  shader::setInt(skyboxShader, "skybox", 0)
  
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
    
    ; draw scene as normal
    shader::use(shader)
    Protected.math::mat4x4 model, *view, projection
    math::Mat4x4_set_Scalar(model, 1)
    *view = camera::GetViewMatrix(*camera)
    math::perspective(projection, Radian(camera::GetZoom(*camera)), window::GetAspect(), 0.1, 100.0)
    shader::setMat4x4(shader, "model", model)
    shader::setMat4x4(shader, "view", *view)
    shader::setMat4x4(shader, "projection", projection)
    shader::setVec3(shader, "cameraPos", camera::GetPosition(*camera) )
    ; cubes
    gl::BindVertexArray(cubeVAO)
    gl::ActiveTexture(GL::#TEXTURE0)
    gl::BindTexture(GL::#TEXTURE_CUBE_MAP, cubemapTexture) 	
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    gl::BindVertexArray(0)    
    
    ;draw skybox as last
    gl::DepthFunc(GL::#LEQUAL); change depth function so depth test passes when values are equal to depth buffer's content
    shader::use(skyboxShader)
    Protected.math::mat4x4 view
    math::mat4x4_set(view, *view)
    view\v[0]\f[3] = 0 ;remove translation from the view matrix
    view\v[1]\f[3] = 0
    view\v[2]\f[3] = 0
    view\v[3]\f[0] = 0
    view\v[3]\f[1] = 0
    view\v[3]\f[2] = 0
    view\v[3]\f[3] = 1
    Shader::setMat4x4(SkyboxShader, "view", view)
    Shader::setMat4x4(skyboxShader, "projection", projection)
    ;skybox cube
    gl::BindVertexArray(skyboxVAO)
    gl::ActiveTexture(GL::#TEXTURE0)
    gl::BindTexture(GL::#TEXTURE_CUBE_MAP, cubemapTexture)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    gl::BindVertexArray(0)
    gl::DepthFunc(GL::#LESS); set depth function back to default
        
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @cubeVAO)
  gl::DeleteVertexArrays(1, @skyboxVAO)
  gl::DeleteBuffers(1, @cubeVBO)
  gl::DeleteBuffers(1, @skyboxVBO)
  
  texture::delete(cubemapTexture)
  
  shader::Delete(Shader)  
  shader::delete(SkyboxShader)
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





