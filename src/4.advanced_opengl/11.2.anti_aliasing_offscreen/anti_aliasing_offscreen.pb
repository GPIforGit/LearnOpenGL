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
  Protected.l screenShader = shader::new("aa_post.vs", "aa_post.fs")
  
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
    
    quadVertices: ;vertex attributes for a quad that fills the entire screen in Normalized Device Coordinates.
    ;      positions    texCoords
    Data.f -1.0,  1.0,  0.0, 1.0, ;1
           -1.0, -1.0,  0.0, 0.0,
           1.0, -1.0,  1.0, 0.0,
           -1.0,  1.0,  0.0, 1.0, ;2
           1.0, -1.0,  1.0, 0.0,
           1.0,  1.0,  1.0, 1.0
    quadVerticesEnd:
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
  
  ; setup screen VAO
  Protected.l quadVAO, quadVBO
  gl::GenVertexArrays(1, @quadVAO)
  gl::GenBuffers(1, @quadVBO)
  gl::BindVertexArray(quadVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, quadVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?quadVerticesEnd - ?quadVertices, ?quadVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 2, GL::#FLOAT, GL::#False, 4 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(1)
  gl::VertexAttribPointer(1, 2, GL::#FLOAT, GL::#False, 4 * SizeOf(float), 2 * SizeOf(float))
  
  ; configure MSAA framebuffer
  ; --------------------------
  Protected.l framebuffer
  gl::GenFramebuffers(1, @framebuffer)
  gl::BindFramebuffer(GL::#FRAMEBUFFER, framebuffer)
  ; create a multisampled color attachment texture
  Protected.l textureColorBufferMultiSampled
  gl::GenTextures(1, @textureColorBufferMultiSampled);
  gl::BindTexture(GL::#TEXTURE_2D_MULTISAMPLE, textureColorBufferMultiSampled)
  gl::TexImage2DMultisample(GL::#TEXTURE_2D_MULTISAMPLE, 4, GL::#RGB, #SCR_WIDTH, #SCR_HEIGHT, GL::#True)
  gl::BindTexture(GL::#TEXTURE_2D_MULTISAMPLE, 0)
  gl::FramebufferTexture2D(GL::#FRAMEBUFFER, GL::#COLOR_ATTACHMENT0, GL::#TEXTURE_2D_MULTISAMPLE, textureColorBufferMultiSampled, 0)
  
  ; create a (also multisampled) renderbuffer object for depth and stencil attachments
  Protected.l rbo
  gl::GenRenderbuffers(1, @rbo)
  gl::BindRenderbuffer(GL::#RENDERBUFFER, rbo)
  gl::RenderbufferStorageMultisample(GL::#RENDERBUFFER, 4, GL::#DEPTH24_STENCIL8, #SCR_WIDTH, #SCR_HEIGHT)
  gl::BindRenderbuffer(GL::#RENDERBUFFER, 0)                                                          
  gl::FramebufferRenderbuffer(GL::#FRAMEBUFFER, GL::#DEPTH_STENCIL_ATTACHMENT, GL::#RENDERBUFFER, rbo)    
  
  If gl::CheckFramebufferStatus(GL::#FRAMEBUFFER) <> GL::#FRAMEBUFFER_COMPLETE
    Debug "ERROR::FRAMEBUFFER:: Framebuffer is not complete!"
    CallDebugger
    End
  EndIf
  gl::BindFramebuffer(GL::#FRAMEBUFFER, 0);
  
  ; configure second post-processing framebuffer
  Protected.l intermediateFBO
  gl::GenFramebuffers(1, @intermediateFBO)
  gl::BindFramebuffer(GL::#FRAMEBUFFER, intermediateFBO)
  
  ; create a color attachment texture
  Protected.l screenTexture
  gl::GenTextures(1, @screenTexture)
  gl::BindTexture(GL::#TEXTURE_2D, screenTexture)
  gl::TexImage2D(GL::#TEXTURE_2D, 0, GL::#RGB, #SCR_WIDTH, #SCR_HEIGHT, 0, GL::#RGB, GL::#UNSIGNED_BYTE, #Null)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MIN_FILTER, GL::#LINEAR)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MAG_FILTER, GL::#LINEAR)
  gl::FramebufferTexture2D(GL::#FRAMEBUFFER, GL::#COLOR_ATTACHMENT0, GL::#TEXTURE_2D, screenTexture, 0)	; we only need a color buffer
  
  If gl::CheckFramebufferStatus(GL::#FRAMEBUFFER) <> GL::#FRAMEBUFFER_COMPLETE
    Debug "ERROR::FRAMEBUFFER:: Intermediate Framebuffer is not complete!"
    CallDebugger
    End
  EndIf
    
  ;shader configuration
  ; --------------------
  shader::use(shader)
  shader::setInt(screenShader, "screenTexture", 0)
  
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
    
    ; 1. draw scene as normal in multisampled buffers
    gl::BindFramebuffer(GL::#FRAMEBUFFER, framebuffer)
    gl::ClearColor(0.1, 0.1, 0.1, 1.0)          
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    gl::Enable(GL::#DEPTH_TEST)                           
    
    ; set transformation matrices		
    shader::use(shader)
    Protected.math::mat4x4 projection
    math::perspective(projection, Radian(camera::GetZoom(*camera)), window::GetAspect(), 0.1, 1000.0)
    shader::setMat4x4(shader, "projection", projection)
    shader::setMat4x4(shader, "view", camera::GetViewMatrix(*camera))
    shader::setMat4x4(shader, "model", math::m4_1)
    
    gl::BindVertexArray(cubeVAO)
    gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    
    ; 2. now blit multisampled buffer(s) to normal colorbuffer of intermediate FBO. Image is stored in screenTexture
    gl::BindFramebuffer(GL::#READ_FRAMEBUFFER, framebuffer)
    gl::BindFramebuffer(GL::#DRAW_FRAMEBUFFER, intermediateFBO)
    gl::BlitFramebuffer(0, 0, #SCR_WIDTH, #SCR_HEIGHT, 0, 0, #SCR_WIDTH, #SCR_HEIGHT, GL::#COLOR_BUFFER_BIT, GL::#NEAREST)
    
    ; 3. now render quad with scene's visuals as its texture image
    gl::BindFramebuffer(GL::#FRAMEBUFFER, 0)
    gl::ClearColor(1.0, 1.0, 1.0, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT)
    gl::Disable(GL::#DEPTH_TEST)
    
    ; draw Screen quad
    shader::use(screenShader)
    gl::BindVertexArray(quadVAO)
    gl::ActiveTexture(GL::#TEXTURE0)
    gl::BindTexture(GL::#TEXTURE_2D, screenTexture); use the now resolved color attachment as the quad's texture
    gl::DrawArrays(GL::#TRIANGLES, 0, 6)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  
  gl::DeleteVertexArrays(1, @cubeVAO)
  gl::DeleteBuffers(1, @cubeVBO)
  
  gl::DeleteVertexArrays(1, @quadVAO)
  gl::DeleteBuffers(1, @quadVBO)
  
  gl::DeleteFramebuffers(1, @framebuffer)
  gl::DeleteTextures(1, @textureColorBufferMultiSampled)
  gl::DeleteRenderbuffers(1, @rbo)
  
  gl::DeleteFramebuffers(1, @intermediateFBO)
  gl::DeleteTextures(1, @screenTexture)
  
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





