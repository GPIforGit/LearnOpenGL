EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Framebuffers

; note:
; Framebuffer don't use multisampling, you must do additional steps to activate this
; When you resize the window and need to resize the Framebuffer it is better to delete the framebuffer
; and recreating it. This code is missing here.


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
  Protected.l Shader = shader::new("framebuffers.vs", "framebuffers.fs")
  Protected.l ScreenShader = shader::new("framebuffers_screen.vs","framebuffers_screen.fs")
  
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
    ; positions              texture Coords
    Data.f 5.0, -0.5,  5.0,  2.0, 0.0, ;1
           -5.0, -0.5,  5.0,  0.0, 0.0,
           -5.0, -0.5, -5.0,  0.0, 2.0,
           5.0, -0.5,  5.0,  2.0, 0.0, ;2
           -5.0, -0.5, -5.0,  0.0, 2.0,
           5.0, -0.5, -5.0,  2.0, 2.0								
    planeVerticesEnd:
    
    quadVertices:
    ; vertex attributes for a quad that fills the entire screen in Normalized Device Coordinates.
    ;       positions  texCoords
    Data.f -1.0,  1.0,  0.0, 1.0, ;1
           -1.0, -1.0,  0.0, 0.0,
           1.0, -1.0,  1.0, 0.0,
           -1.0,  1.0,  0.0, 1.0, ;2
           1.0, -1.0,  1.0, 0.0,
           1.0,  1.0,  1.0, 1.0
    quadVerticesEnd:
    
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
  ; screen quad VAO
  Protected.l quadVAO, quadVBO
  gl::GenVertexArrays(1, @quadVAO)
  gl::GenBuffers(1, @quadVBO)
  gl::BindVertexArray(quadVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, quadVBO);
  gl::BufferData(GL::#ARRAY_BUFFER, ?quadVerticesEnd-?quadVertices, ?quadVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 2, GL::#FLOAT, GL::#False, 4 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(1)
  gl::VertexAttribPointer(1, 2, GL::#FLOAT, GL::#False, 4 * SizeOf(float), 2 * SizeOf(float))
  gl::BindVertexArray(0)
  
  ; load textures
  ; -------------
  Protected.l cubeTexture  = texture::Load("../../../resources/textures/marble.jpg")
  Protected.l floorTexture = texture::load("../../../resources/textures/metal.png")
  
  ; shader configuration
  ; --------------------
  shader::use(shader)
  shader::setInt(shader,"texture1", 0)
  
  shader::use(screenShader)
  shader::setInt(screenShader, "screenTexture", 0)
  
  ; framebuffer configuration
  ; -------------------------
  Protected.l framebuffer
  gl::GenFramebuffers(1, @framebuffer)
  gl::BindFramebuffer(GL::#FRAMEBUFFER, framebuffer)
  ; create a color attachment texture
  Protected.l textureColorbuffer
  gl::GenTextures(1, @textureColorbuffer);
  gl::BindTexture(GL::#TEXTURE_2D, textureColorbuffer)
  gl::TexImage2D(GL::#TEXTURE_2D, 0, GL::#RGB, window::GetWidth(), window::GetHeight(), 0, GL::#RGB, GL::#UNSIGNED_BYTE, #Null)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MIN_FILTER, GL::#LINEAR)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MAG_FILTER, GL::#LINEAR)
  gl::FramebufferTexture2D(GL::#FRAMEBUFFER, GL::#COLOR_ATTACHMENT0, GL::#TEXTURE_2D, textureColorbuffer, 0)
  
  ; create a renderbuffer object for depth and stencil attachment (we won't be sampling these)
  Protected.l rbo
  gl::GenRenderbuffers(1, @rbo)
  gl::BindRenderbuffer(GL::#RENDERBUFFER, rbo)
  gl::RenderbufferStorage(GL::#RENDERBUFFER, GL::#DEPTH24_STENCIL8, window::GetWidth(), window::GetHeight());  use a single renderbuffer object for both a depth AND stencil buffer.
  gl::FramebufferRenderbuffer(GL::#FRAMEBUFFER, GL::#DEPTH_STENCIL_ATTACHMENT, GL::#RENDERBUFFER, rbo)      ; now actually attach it
                                                                                                            ; now that we actually created the framebuffer and added all attachments we want To check If it is actually complete now
  If gl::CheckFramebufferStatus(GL::#FRAMEBUFFER) <> GL::#FRAMEBUFFER_COMPLETE
    Debug "ERROR::FRAMEBUFFER:: Framebuffer is not complete!"
  EndIf
  gl::BindFramebuffer(GL::#FRAMEBUFFER, 0)
  
  ; draw as wireframe
  ;gl::PolygonMode(GL::#FRONT_AND_BACK, GL::#LINE)
  
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
    
    ; bind to framebuffer and draw scene as we normally would to color texture 
    gl::BindFramebuffer(GL::#FRAMEBUFFER, framebuffer)
    gl::Enable(GL::#DEPTH_TEST);  enable depth testing (is disabled for rendering screen-space quad)
       
    ; make sure we clear the framebuffer's content
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
    
    ; now bind back to default framebuffer and draw a quad plane with the attached framebuffer color texture
    gl::BindFramebuffer(GL::#FRAMEBUFFER, 0)
    gl::Disable(GL::#DEPTH_TEST);  disable depth test so screen-space quad isn't discarded due to depth test.
    
    ; clear all relevant buffers
    gl::ClearColor(1.0, 1.0, 1.0, 1.0); set clear color to white (not really necessary actually, since we won't be able to see behind the quad anyways)
    gl::Clear(GL::#COLOR_BUFFER_BIT)
    
    shader::use(screenShader)
    gl::BindVertexArray(quadVAO)
    gl::BindTexture(GL::#TEXTURE_2D, textureColorbuffer);	 use the color attachment texture as the texture of the quad plane
    gl::DrawArrays(GL::#TRIANGLES, 0, 6)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @cubeVAO)
  gl::DeleteVertexArrays(1, @planeVAO)
  gl::DeleteVertexArrays(1, @quadVAO)
  gl::DeleteBuffers(1, @cubeVBO)
  gl::DeleteBuffers(1, @planeVBO)
  gl::DeleteBuffers(1, @quadVBO)
  
  texture::Delete(floorTexture)
  texture::delete(cubeTexture)
  
  shader::Delete(Shader)  
  shader::delete(screenShader)
  camera::delete(*camera):*camera = #Null
  
  gl::DeleteFramebuffers(1, @framebuffer)
  gl::DeleteTextures(1, @textureColorbuffer)
  gl::DeleteRenderbuffers(1, @rbo)
  
  
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





