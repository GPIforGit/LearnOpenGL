EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Instancing

; changes:
; - glDrawElementsInstanced is called in the mesh/model-module. the original code required to access direct the meshes-data. My solution is more clean.
; - increased the scale of the planet to look a little bit better
; - speed up the movement a little bit

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
Global *camera = camera::new_float(0,10,200)
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
  Protected.l asteroidShader = shader::new("asteroids.vs", "asteroids.fs")
  Protected.l planetShader = shader::new("planet.vs", "planet.fs")
  
  ; load models
  ; -----------
  Protected.i rock = model::new("../../../resources/objects/rock/rock.obj", ai::#Process_Triangulate | ai::#Process_GenSmoothNormals | ai::#Process_CalcTangentSpace) ; remove | ai::#Process_FlipUVs
  Protected.i planet = model::new("../../../resources/objects/planet/planet.obj", ai::#Process_Triangulate | ai::#Process_GenSmoothNormals | ai::#Process_CalcTangentSpace) ; remove | ai::#Process_FlipUVs
  
  ; generate a large list of semi-random model transformation matrices
  ; ------------------------------------------------------------------
  Protected.l amount = 100000
  Dim modelMatrices.math::mat4x4(amount-1)
  Protected.f radius = 150.0
  Protected.f offset = 25.0
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
  
  ; configure instanced array
  ; -------------------------
  Protected.l buffer
  gl::GenBuffers(1, @buffer)
  gl::BindBuffer(GL::#ARRAY_BUFFER, buffer);
  gl::BufferData(GL::#ARRAY_BUFFER, amount * SizeOf(math::mat4x4), @modelMatrices(), GL::#STATIC_DRAW)
  
  ; set transformation matrices as an instance vertex attribute (with divisor 1)
  ; -----------------------------------------------------------------------------------------------------------------------------------
  Protected.l meshCount
  Protected.integer *meshes = model::GetMeshArray(rock, @meshCount)
  ; mesh array is a integer array of the meshes in this model. The list is zero-terminated
  ; model can contain more than one mesh
  While *meshes\i
    ; bind the vertexarray of the mesh, so we can add attributes.
    mesh::BindVertexArray( *meshes\i )
    ; set attribute pointers for matrix (4 times vec4)
    gl::EnableVertexAttribArray(3);
    gl::VertexAttribPointer(3, 4, GL::#FLOAT, GL::#False, SizeOf(math::Mat4x4), 0)
    gl::EnableVertexAttribArray(4);
    gl::VertexAttribPointer(4, 4, GL::#FLOAT, GL::#False, SizeOf(math::Mat4x4), 1 * SizeOf(math::vec4))
    gl::EnableVertexAttribArray(5);
    gl::VertexAttribPointer(5, 4, GL::#FLOAT, GL::#False, SizeOf(math::Mat4x4), 2 * SizeOf(math::vec4))
    gl::EnableVertexAttribArray(6);
    gl::VertexAttribPointer(6, 4, GL::#FLOAT, GL::#False, SizeOf(math::Mat4x4), 3 * SizeOf(math::vec4))
    
    gl::VertexAttribDivisor(3, 1)
    gl::VertexAttribDivisor(4, 1)
    gl::VertexAttribDivisor(5, 1)
    gl::VertexAttribDivisor(6, 1)
    
    gl::BindVertexArray(0)
    *meshes + SizeOf(integer)
  Wend
  
  
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
    
    shader::use(asteroidShader)
    shader::setMat4x4(asteroidShader, "projection", projection)
    shader::setMat4x4(asteroidShader, "view", *view)
    
    shader::use(planetShader)
    shader::setMat4x4(planetShader, "projection", projection)
    shader::setMat4x4(planetShader, "view", *view)
    
    ; draw planet
    Protected.math::mat4x4 model
    math::Mat4x4_set_Scalar( model, 1)
    math::translate_float( model, model, 0.0, -3.0, 0.0)
    math::scale_float( model, model , 20.0, 20.0, 20.0)
    shader::use(planetShader)
    shader::setMat4x4(planetShader, "model", model)
    model::Draw(planet, planetShader)
    
    ; draw meteorites
    shader::use(asteroidShader)
    model::DrawInstanced(rock, asteroidShader,amount)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  
  model::delete(rock)
  model::delete(planet)
  
  shader::delete(asteroidShader)
  shader::Delete(planetShader)  
  
  camera::delete(*camera):*camera = #Null
  
  gl::DeleteBuffers(1, @buffer)
  
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
  
  Protected.f cameraSpeed = 10 * deltaTime 
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





