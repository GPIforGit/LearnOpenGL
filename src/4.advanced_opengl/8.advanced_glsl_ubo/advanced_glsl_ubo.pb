EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Advanced-GLSL

; changes
; - move projection matrix to the window::hasResized() block

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
  
  ; build and compile shaders
  ; -------------------------
  Protected.l ShaderRed = shader::new("advanced_glsl.vs", "red.fs")
  Protected.l ShaderGreen = shader::new("advanced_glsl.vs", "green.fs")
  Protected.l ShaderBlue = shader::new("advanced_glsl.vs", "blue.fs")
  Protected.l ShaderYellow = shader::new("advanced_glsl.vs", "yellow.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    cubeVertices:
    ;         positions           
    Data.f    -0.5, -0.5, -0.5,   ;1
              0.5, -0.5, -0.5,  
              0.5,  0.5, -0.5,  
              0.5,  0.5, -0.5,  
              -0.5,  0.5, -0.5,  
              -0.5, -0.5, -0.5,  
              -0.5, -0.5,  0.5,   ;2
              0.5, -0.5,  0.5,  
              0.5,  0.5,  0.5,  
              0.5,  0.5,  0.5,  
              -0.5,  0.5,  0.5,  
              -0.5, -0.5,  0.5,  
              -0.5,  0.5,  0.5,  ;3
              -0.5,  0.5, -0.5, 
              -0.5, -0.5, -0.5, 
              -0.5, -0.5, -0.5, 
              -0.5, -0.5,  0.5, 
              -0.5,  0.5,  0.5, 
              0.5,  0.5,  0.5,   ;4
              0.5,  0.5, -0.5,  
              0.5, -0.5, -0.5,  
              0.5, -0.5, -0.5,  
              0.5, -0.5,  0.5,  
              0.5,  0.5,  0.5,  
              -0.5, -0.5, -0.5,  ;5
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
  
  ; cube VAO
  Protected.l cubeVAO, cubeVBO
  gl::GenVertexArrays(1, @cubeVAO)
  gl::GenBuffers(1, @cubeVBO)
  gl::BindVertexArray(cubeVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, cubeVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?cubeVerticesEnd - ?cubeVertices, ?cubeVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 3 * SizeOf(float), 0)  
  gl::BindVertexArray(0)
  
  ; configure a uniform buffer object
  ; ---------------------------------
  ; first. We get the relevant block indices
  Protected.l uniformBlockIndexRed = gl::GetUniformBlockIndex(shaderRed, "Matrices")
  Protected.l uniformBlockIndexGreen = gl::GetUniformBlockIndex(shaderGreen, "Matrices")
  Protected.l uniformBlockIndexBlue = gl::GetUniformBlockIndex(shaderBlue, "Matrices")
  Protected.l uniformBlockIndexYellow = gl::GetUniformBlockIndex(shaderYellow, "Matrices")
  ; then we link each shader's uniform block to this uniform binding point
  gl::UniformBlockBinding(shaderRed, uniformBlockIndexRed, 0);
  gl::UniformBlockBinding(shaderGreen, uniformBlockIndexGreen, 0);
  gl::UniformBlockBinding(shaderBlue, uniformBlockIndexBlue, 0)  ;
  gl::UniformBlockBinding(shaderYellow, uniformBlockIndexYellow, 0);
                                                                   ; Now actually create the buffer
  Protected.l uboMatrices
  gl::GenBuffers(1, @uboMatrices)
  gl::BindBuffer(GL::#UNIFORM_BUFFER, uboMatrices)
  gl::BufferData(GL::#UNIFORM_BUFFER, 2 * SizeOf(math::mat4x4), #Null, GL::#STATIC_DRAW)
  gl::BindBuffer(GL::#UNIFORM_BUFFER, 0)
  
  ; define the range of the buffer that links to a uniform binding point
  gl::BindBufferRange(GL::#UNIFORM_BUFFER, 0, uboMatrices, 0, 2 * SizeOf(math::mat4x4))
  
  
  
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
      
      ; store the projection matrix (we only do this once now) (note: we're not using zoom anymore by changing the FoV)
      Protected.math::mat4x4 projection 
      math::perspective(projection, Radian(45.0), window::GetAspect(), 0.1, 100.0)
      gl::BindBuffer(GL::#UNIFORM_BUFFER, uboMatrices)
      gl::BufferSubData(GL::#UNIFORM_BUFFER, 0, SizeOf(math::mat4x4), projection)
      gl::BindBuffer(GL::#UNIFORM_BUFFER, 0)
      
    EndIf
    
    ; render
    ; ------
    
    gl::ClearColor(0.1, 0.1, 0.1, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    
    ; set the view and projection matrix in the uniform block - we only have to do this once per loop iteration.
    Protected.math::mat4x4 *view = camera::GetViewMatrix(*camera)
    gl::BindBuffer(GL::#UNIFORM_BUFFER, uboMatrices)
    gl::BufferSubData(GL::#UNIFORM_BUFFER, SizeOf(math::mat4x4), SizeOf(math::mat4x4), *view)
    gl::BindBuffer(GL::#UNIFORM_BUFFER, 0)
    
    ; draw 4 cubes 
    ; RED
    gl::BindVertexArray(cubeVAO)
    shader::use(shaderRed)
    Protected.math::mat4x4 model
    math::Mat4x4_set_Scalar(model, 1)
    math::translate_float(model, model, -0.75, 0.75, 0.0);  move top-left
    shader::setMat4x4(shaderRed, "model", model)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    ; GREEN
    shader::use(ShaderGreen)
    math::Mat4x4_set_Scalar(model, 1)
    math::translate_float(model, model, 0.75, 0.75, 0.0);  move top-right
    shader::setMat4x4(ShaderGreen, "model", model)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    ; YELLOW
    shader::use(ShaderYellow)
    math::Mat4x4_set_Scalar(model, 1)
    math::translate_float(model, model, -0.75, -0.75, 0.0);  move bottom-left
    shader::setMat4x4(ShaderYellow, "model", model)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    ; BLUE
    shader::use(ShaderBlue)
    math::Mat4x4_set_Scalar(model, 1)
    math::translate_float(model, model, 0.75, -0.75, 0.0);  move bottom-right
    shader::setMat4x4(ShaderBlue, "model", model)
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
  
  gl::DeleteBuffers(1, @uboMatrices)
  
  
  shader::Delete(ShaderBlue)  
  shader::Delete(ShaderRed)  
  shader::Delete(ShaderGreen)  
  shader::Delete(ShaderYellow)  
  
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
  
  ;   If window::GetMouseWheelY()
  ;     camera::ProcessMouseScroll( *camera, window::GetMouseWheelY() )
  ;   EndIf
  
  
EndProcedure





