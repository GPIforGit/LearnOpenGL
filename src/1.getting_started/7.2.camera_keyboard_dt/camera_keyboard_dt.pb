EnableExplicit

; https://learnopengl.com/Getting-started/Camera

; changes
; delta-time is already in the render loop


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

Declare processInput(deltaTime.d)

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

; camera
Global.math::Vec3 cameraPos, cameraFront, cameraUp
math::vec3_set_float( cameraPos   , 0.0, 0.0,  3.0)
math::vec3_set_float( cameraFront , 0.0, 0.0, -1.0)
math::vec3_set_float( cameraUp    , 0.0, 1.0,  0.0)

; timing
Global.sdl::ext_Timer delta_timer
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
  
  ; pass projection matrix to shader (as projection matrix rarely changes there's no need to do this per frame)
  ; -----------------------------------------------------------------------------------------------------------
  Protected.math::mat4x4 projection
  math::perspective(projection, Radian(45.0), window::GetAspect(), 0.1, 100.0) ; note, when you resize the window you should update the projection matrix!
  gl::UniformMatrix4fv(projectionLoc, 1, #False, projection)  
  
  ;- render loop  
  ;  -----------
  While Not window::WindowShouldClose()
    
    ; per-frame time logic
    ; --------------------
    deltaTime = sdl::ext_DeltaSeconds(delta_Timer)
    
    ; input
    ; -----
    processInput(deltaTime)
    
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
    
    ; create transformations
    Protected.math::mat4x4 view
    Protected.math::vec3 tmpv3
    math::lookAt(view,
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
Procedure processInput(deltaTime.d)
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

  
  
EndProcedure


