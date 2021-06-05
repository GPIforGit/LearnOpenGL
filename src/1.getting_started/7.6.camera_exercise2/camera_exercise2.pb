EnableExplicit

; https://learnopengl.com/Getting-started/Camera

; changes
; This time, i used the 7.3.camera_mouse_zoom - code, because I don't want to change the code of the camera_class


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
XIncludeFile "../../../common/window.pbi"

Declare processInput()
Declare.i calculate_lookAt_matrix(*res.math::mat4x4, *position.math::vec3, *target.math::vec3, *worldUp.math::vec3)

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

; camera
Global.math::Vec3 cameraPos, cameraFront, cameraUp
math::vec3_set_float( cameraPos   , 0.0, 0.0,  3.0)
math::vec3_set_float( cameraFront , 0.0, 0.0, -1.0)
math::vec3_set_float( cameraUp    , 0.0, 1.0,  0.0)

Global.l firstMouse = #True
Global.f yaw   = -90.0;	 yaw is initialized to -90.0 degrees since a yaw of 0.0 results in a direction vector pointing to the right so we initially rotate a bit to the left.
Global.f pitch =  0.0
Global.f lastX =  800.0 / 2.0
Global.f lastY =  600.0 / 2.0
Global.f fov   =  45.0

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
  Protected.l ourShader = shader::new("camera.vs", "camera.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    vertices:
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
    vertices_end:
    
    indices: 
    Data.l 0, 1, 3, ; first triangle
           1, 2, 3  ; second triangle
    indices_end:
    
    ; world space positions of our cubes
    cubePositions:
    Data.f  0.0,  0.0,  0.0
    Data.f  2.0,  5.0, -15.0
    Data.f -1.5, -2.2, -2.5
    Data.f -3.8, -2.0, -12.3
    Data.f  2.4, -0.4, -3.5
    Data.f -1.7,  3.0, -7.5
    Data.f  1.3, -2.0, -2.5
    Data.f  1.5,  2.0, -2.5
    Data.f  1.5,  0.2, -1.5
    Data.f -1.3,  1.0, -1.5
    cubePositionsEnd:
  EndDataSection
  Global.math::vec3Array *cubePosition = ?cubePositions
  Global.l sizeCubePosition = (?cubePositionsEnd - ?cubePositions) / SizeOf(math::vec3)  
  
  Protected.l VBO, VAO
  gl::GenVertexArrays(1, @VAO)
  gl::GenBuffers(1, @VBO)
  
  gl::BindVertexArray(VAO)
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?vertices_end - ?vertices, ?vertices, GL::#STATIC_DRAW)
  
  ; position attribute
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(0)
  
  ; texture coord attribute
  gl::VertexAttribPointer(1, 2, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 3 * SizeOf(float))
  gl::EnableVertexAttribArray(1)
  
  ; load and create a texture 
  ; -------------------------
  Protected.l texture1, texture2
  ; texture 1
  ; ---------
  gl::GenTextures(1, @texture1)
  gl::BindTexture(GL::#TEXTURE_2D, texture1)
  ; set the texture wrapping parameters
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_S, GL::#REPEAT) 
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_T, GL::#REPEAT)
  ; set texture filtering parameters
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MIN_FILTER, GL::#LINEAR_MIPMAP_LINEAR)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MAG_FILTER, GL::#LINEAR)
  ; load image, create texture and generate mipmaps
  Protected.sdl::Surface *surface, *converted_surface
  *surface = sdl::IMG_Load("../../../resources/textures/container.jpg")
  If *surface
    ; convert to RGB with 8Bit per Pixels, last parameter is always 0 (sdl1 leftover)
    *converted_surface = sdl::ConvertSurfaceFormat(*surface, sdl::#PIXELFORMAT_RGB24 ,0)
    ; vertical flip
    sdl::ext_Surface_FlipVertical(*converted_surface)
    
    gl::TexImage2D(GL::#TEXTURE_2D, 0, GL::#RGB, *converted_surface\w, *converted_surface\h, 0, GL::#RGB, GL::#UNSIGNED_BYTE, *converted_surface\pixels)
    gl::GenerateMipmap(GL::#TEXTURE_2D)
    
    ;clean up
    sdl::FreeSurface( *surface )
    sdl::FreeSurface( *converted_surface )
  Else
    Debug "Failed to load texture"
  EndIf
  ; texture 2 (with alpha!)
  ; -----------------------
  gl::GenTextures(1, @texture2)
  gl::BindTexture(GL::#TEXTURE_2D, texture2)
  ; set the texture wrapping parameters
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_S, GL::#REPEAT)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_T, GL::#REPEAT)
  ; set texture filtering parameters
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MIN_FILTER, GL::#LINEAR_MIPMAP_LINEAR)
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MAG_FILTER, GL::#LINEAR)
  ; load image, create texture and generate mipmaps
  *surface = sdl::IMG_Load("../../../resources/textures/awesomeface.png")
  If *surface
    ; convert to RGBA with 8Bit per Pixels, last parameter is always 0 (sdl1 leftover)
    *converted_surface = sdl::ConvertSurfaceFormat(*surface, sdl::#PIXELFORMAT_RGBA32 ,0)
    ; vertical flip
    sdl::ext_Surface_FlipVertical(*converted_surface)
    
    gl::TexImage2D(GL::#TEXTURE_2D, 0, GL::#RGBA, *converted_surface\w, *converted_surface\h, 0, GL::#RGBA, GL::#UNSIGNED_BYTE, *converted_surface\pixels)
    gl::GenerateMipmap(GL::#TEXTURE_2D)
    
    ;clean up
    sdl::FreeSurface( *surface )
    sdl::FreeSurface( *converted_surface )
  Else
    Debug "Failed to load texture"
  EndIf
  
  ; tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
  ; -------------------------------------------------------------------------------------------
  shader::use(ourShader)
  shader::setInt(ourShader, "texture1", 0)
  shader::setInt(ourShader, "texture2", 1)
  Protected.l transformLoc = gl::GetUniformLocation(ourShader, "transform"); moved outside the render loop
  
  ; retrieve the matrix uniform locations
  shader::use( ourShader )
  Protected.l modelLoc      = gl::GetUniformLocation(ourShader, "model")
  Protected.l viewLoc       = gl::GetUniformLocation(ourShader, "view")
  Protected.l projectionLoc = gl::GetUniformLocation(ourShader, "projection")
  
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
    
    gl::ClearColor(0.2, 0.3, 0.3, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    
    ; bind textures on corresponding texture units
    gl::ActiveTexture(GL::#TEXTURE0)
    gl::BindTexture(GL::#TEXTURE_2D, texture1)
    gl::ActiveTexture(GL::#TEXTURE1)
    gl::BindTexture(GL::#TEXTURE_2D, texture2)
    
    ; activate shader
    shader::use(ourShader)
    
    ; pass projection matrix to shader (note that in this case it could change every frame)
    ; -------------------------------------------------------------------------------------
    Protected.math::mat4x4 projection
    math::perspective(projection, Radian(fov), window::GetAspect(), 0.1, 100.0) ; note, when you resize the window you should update the projection matrix!
    gl::UniformMatrix4fv(projectionLoc, 1, #False, projection)  
    
    ; create transformations
    Protected.math::mat4x4 view
    Protected.math::vec3 tmpv3
    calculate_lookAt_matrix(view,
                 cameraPos, 
                 math::vec3_add( tmpv3, cameraPos , cameraFront), 
                 cameraUp)
    
    gl::UniformMatrix4fv(viewLoc, 1, #False, view)
    
    ; render boxes
    gl::BindVertexArray(VAO)
    Protected.l i
    For i=0 To sizeCubePosition-1
      ; calculate the model matrix for each object and pass it to shader before drawing
      Protected.math::mat4x4 model
      math::Mat4x4_set_Scalar(model, 1)
      math::translate(model, model, *cubePosition\v[i])
      
      Protected.f angle = 20.0 * i       
      math::rotate_float(model, model, Radian(angle), 1.0, 0.3, 0.5)
      gl::UniformMatrix4fv(modelLoc, 1, #False, model)
      gl::DrawArrays(GL::#TRIANGLES, 0, 36)
    Next
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @VAO)
  gl::DeleteBuffers(1, @VBO)
  shader::Delete(ourShader)  
  
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
    math::vec3_mul_scalar(tmp, cameraFront, cameraSpeed)
    math::vec3_add(cameraPos, cameraPos, tmp)
  EndIf
  If window::GetKey(sdl::#scancode_s)
    math::vec3_mul_scalar(tmp, cameraFront, cameraSpeed)
    math::vec3_sub(cameraPos, cameraPos, tmp)
  EndIf
  If window::GetKey(sdl::#scancode_a)    
    math::normalize(tmp, math::Vec3_Cross(tmp, cameraFront, cameraUp))
    math::vec3_mul_scalar(tmp, tmp, cameraSpeed)
    math::vec3_sub(cameraPos, cameraPos, tmp)
    
  EndIf
  If window::GetKey(sdl::#scancode_d)    
    math::normalize(tmp, math::Vec3_Cross(tmp, cameraFront, cameraUp))
    math::vec3_mul_scalar(tmp, tmp, cameraSpeed)
    math::vec3_add(cameraPos, cameraPos, tmp)
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
      
      Protected.f sensitivity = 0.1; change this value to your liking
      xoffset * sensitivity
      yoffset * sensitivity
      
      yaw + xoffset
      pitch + yoffset
      
      If pitch > 89.0
        pitch = 89.0
      ElseIf pitch < -89.0
        pitch = -89.0
      EndIf
      
      Protected.math::vec3 front
      front\x = Cos(Radian(yaw)) * Cos(Radian(pitch))
      front\y = Sin(Radian(pitch))                         
      front\z = Sin(Radian(yaw)) * Cos(Radian(pitch))
      math::normalize(cameraFront,front)
    EndIf
  Else
    firstMouse = #True ; restart relative
  EndIf
  
  If window::GetMouseWheelY()
    fov - window::GetMouseWheelY()
    If fov < 1.0
      fov = 1.0
    ElseIf fov > 91
      fov = 91
    EndIf
  EndIf
  
  
EndProcedure

;Custom implementation of the LookAt function
Procedure.i calculate_lookAt_matrix(*res.math::mat4x4, *position.math::vec3, *target.math::vec3, *worldUp.math::vec3)  
  ; 1. Position = known
  ; 2. Calculate cameraDirection
  Protected.math::vec3 zaxis
  math::vec3_normalize(zaxis, math::Vec3_sub(zaxis, *position, *target))
  
  ; 3. Get positive right axis vector
  Protected.math::vec3 xaxis  
  math::vec3_normalize(xaxis, math::Vec3_Cross( xaxis, math::vec3_normalize( xaxis, *worldup), zaxis) )
  
  ;4. Calculate camera up vector
  Protected.math::vec3 yaxis
  math::Vec3_Cross( yaxis, zaxis, xaxis)
  
  ; Create translation and rotation matrix
  ; In glm we access elements as mat[col][row] due To column-major layout
  Protected.math::mat4x4 translation 
  math::Mat4x4_set_Scalar( translation,1) ; Identity matrix by default
  translation\v[3]\f[0] = - *position\x             ; Third column, first row
  translation\v[3]\f[1] = - *position\y
  translation\v[3]\f[2] = - *position\z
  
  Protected.math::mat4x4 rotation 
  math::Mat4x4_set_Scalar( rotation,1)
  rotation\v[0]\f[0] = xaxis\x; First column, first row
  rotation\v[1]\f[0] = xaxis\y
  rotation\v[2]\f[0] = xaxis\z
  rotation\v[0]\f[1] = yaxis\x; First column, second row
  rotation\v[1]\f[1] = yaxis\y
  rotation\v[2]\f[1] = yaxis\z
  rotation\v[0]\f[2] = zaxis\x; First column, third row
  rotation\v[1]\f[2] = zaxis\y
  rotation\v[2]\f[2] = zaxis\z 
  
  ; Return lookAt matrix as combination of translation and rotation matrix
  
  ProcedureReturn math::mat4x4_mul(*res, rotation, translation) ;Remember to read from right to left (first translation then rotation)
EndProcedure


