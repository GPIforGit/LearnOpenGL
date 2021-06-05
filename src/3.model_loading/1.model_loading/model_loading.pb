EnableExplicit

; https://learnopengl.com/Model-Loading/Model

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
XIncludeFile #PB_Compiler_Home + "Include/assimp/assimp.pbi"
XIncludeFile "../../../common/shaders.pbi"
XIncludeFile "../../../common/camera.pbi"
XIncludeFile "../../../common/window.pbi"
XIncludeFile "../../../common/model.pbi"

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
  Protected.l ourShader = shader::new("model_loading.vs", "model_loading.fs")
  
  ; load models
  ; -----------
  Protected  *ourModel = model::new( "../../../resources/objects/backpack/backpack.obj")
  
  ; draw in wireframe
  ; gl::PolygonMode(GL::#FRONT_AND_BACK, GL::#LINE)
  
    
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
    
    gl::ClearColor(0.5, 0.5, 0.5, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    
    ; don't forget to enable shader before setting uniforms
    shader::use( ourShader )
    
    
    ; view/projection transformations    
    Protected.math::mat4x4 projection
    math::perspective(projection, Radian(camera::GetZoom(*camera)), window::GetAspect(), 0.1, 100.0)
    
    Protected.math::mat4x4 *view = camera::GetViewMatrix(*camera)
    
    shader::setMat4x4(ourShader, "projection", projection)
    shader::setMat4x4(ourShader, "view", *view)
    
    ; render the loaded model
    Protected.math::mat4x4 model
    math::Mat4x4_set_Scalar(model, 1)
    math::translate_float(model, model, 0.0, 0.0, 0.0);  translate it down so it's at the center of the scene
    math::scale_float(model, model, 1.0, 1.0, 1.0);	 it's a bit too big for our scene, so scale it down
    shader::setMat4x4(ourShader, "model", model);
    model::Draw(*ourModel, ourShader)
    
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------

  shader::Delete(ourShader)  
  model::delete(*ourModel):*ourModel = #Null
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



