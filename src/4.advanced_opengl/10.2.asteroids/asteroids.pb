EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Instancing

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
;XIncludeFile "../../../common/texture.pbi"
XIncludeFile "../../../common/model.pbi"

Declare processInput()

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

; camera
Global *camera = camera::new_float(0,3,70)
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
  
  ; build and compile shaders
  ; -------------------------
  Protected.l Shader = shader::new("instancing.vs", "instancing.fs")
  
  ; load models
  ; -----------
  Protected.i rock = model::new("../../../resources/objects/rock/rock.obj", ai::#Process_Triangulate | ai::#Process_GenSmoothNormals | ai::#Process_CalcTangentSpace) ; remove | ai::#Process_FlipUVs
  Protected.i planet = model::new("../../../resources/objects/planet/planet.obj", ai::#Process_Triangulate | ai::#Process_GenSmoothNormals | ai::#Process_CalcTangentSpace) ; remove | ai::#Process_FlipUVs
  
  ; generate a large list of semi-random model transformation matrices
  ; ------------------------------------------------------------------
  Protected.l amount = 1000
  Dim modelMatrices.math::mat4x4(amount-1)
  Protected.f radius = 50.0
  Protected.f offset = 2.5
  Protected.l i
  For i=0 To amount -1
    Protected.math::mat4x4 *model = @modelMatrices(i)
    
    math::Mat4x4_set_Scalar( *model, 1 )
    
    ; 1. translation: displace along circle with 'radius' in range [-offset, offset]
    Protected.f angle = i / amount * 360.0
    Protected.f displacement = Random(2 * offset * 100 -1, 0) / 100.0 - offset
    Protected.f x = Sin(angle) * radius + displacement
    displacement = Random(2 * offset * 100 -1, 0) / 100.0 - offset
    Protected.f y = displacement * 0.4; keep height of asteroid field smaller compared to width of x and z
    displacement = Random(2 * offset * 100 -1, 0) / 100.0 - offset
    Protected.f z = Cos(angle) * radius + displacement
    math::translate_float( *model, *model, x,y,z)
    
    ; 2. scale: Scale between 0.05 and 0.25f
    Protected.f scale = Random(20-1,0) / 100.0 + 0.05
    math::scale_float( *model, *model, scale, scale, scale)

    ; 3. rotation: add random rotation around a (semi)randomly picked rotation axis vector
    Protected.f rotAngle = Random(360)
    math::rotate_float( *model, *model, Radian(rotAngle), 0.4, 0.6, 0.8)
  Next
    
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
    
    ; configure transformation matrices
    Protected.math::Mat4x4 projection, *view
    math::perspective(projection, Radian( camera::GetZoom(*camera)), window::GetAspect(), 1.0, 1000.0)
    *view = camera::GetViewMatrix(*camera)
    
    shader::use(shader)
    shader::setMat4x4(shader, "projection", projection)
    shader::setMat4x4(shader, "view", *view)
    
    ; draw planet
    Protected.math::mat4x4 model
    math::Mat4x4_set_Scalar( model, 1)
    math::translate_float( model, model, 0.0, -3.0, 0.0)
    math::scale_float( model, model , 4.0, 4.0, 4.0)
    shader::setMat4x4(shader, "model", model)
    model::Draw(planet, shader)
    
    ; draw meteorites
    For i=0 To amount -1
      shader::setMat4x4(shader, "model", modelMatrices(i))
      model::Draw(rock, shader)
    Next
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  
  model::delete(rock)
  model::delete(planet)
  
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





