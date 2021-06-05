EnableExplicit

; https://learnopengl.com/Getting-started/Transformations

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

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

Procedure main()
  ; initialize, configure and window creation
  ; -----------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH,#SCR_HEIGHT, sdl::#INIT_VIDEO | sdl::#INIT_EVENTS | sdl::#INIT_TIMER, sdl::#IMG_INIT_JPG | sdl::#IMG_INIT_PNG)
    End
  EndIf
  
  ; build and compile our shader program
  ; ------------------------------------
  Protected.l ourShader = shader::new("transform.vs", "transform.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    vertices:
    ;      positions          texture coords
    Data.f 00.5,  0.5, 0.0,   1.0, 1.0, ; top right
           00.5, -0.5, 0.0,   1.0, 0.0, ; bottom right
           -0.5, -0.5, 0.0,   0.0, 0.0, ; bottom left
           -0.5,  0.5, 0.0,   0.0, 1.0  ; top left 
    vertices_end:
    
    indices: 
    Data.l 0, 1, 3, ; first triangle
           1, 2, 3  ; second triangle
    indices_end:
    
  EndDataSection
  
  Protected.l VBO, VAO, EBO
  gl::GenVertexArrays(1, @VAO)
  gl::GenBuffers(1, @VBO)
  gl::GenBuffers(1, @EBO)
  
  gl::BindVertexArray(VAO)
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?vertices_end - ?vertices, ?vertices, GL::#STATIC_DRAW)
  
  gl::BindBuffer(GL::#ELEMENT_ARRAY_BUFFER, EBO)
  gl::BufferData(GL::#ELEMENT_ARRAY_BUFFER, ?indices_end - ?indices, ?indices, GL::#STATIC_DRAW)
  
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
    
  ;- render loop  
  ;  -----------
  While Not window::WindowShouldClose()

    ; input
    ; -----
    processInput()
    
    ; render
    ; ------
    
    gl::ClearColor(0.2, 0.3, 0.3, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT)
    
    ; bind textures on corresponding texture units
    gl::ActiveTexture(GL::#TEXTURE0)
    gl::BindTexture(GL::#TEXTURE_2D, texture1)
    gl::ActiveTexture(GL::#TEXTURE1)
    gl::BindTexture(GL::#TEXTURE_2D, texture2)
    
    ; first container
    ; ---------------
    
    ; create transformations
    Protected.math::mat4x4 transform
    Protected.math::vec3 tmp
    math::Mat4x4_set_Scalar(transform, 1); make sure to initialize matrix to identity matrix first
    math::translate(transform, transform, math::vec3_set_float(tmp, 0.5,-0.5,0.0))
    math::rotate(transform, transform, sdl::ext_GetElapsedSeconds(), math::v3_001)
    
    ; get matrix's uniform location and set matrix
    shader::Use(ourShader)
    gl::UniformMatrix4fv(transformLoc, 1, GL::#False, transform); transform has a structure, so transform and @transform is the same
        
    ; render container
    gl::BindVertexArray(VAO)
    gl::DrawElements(GL::#TRIANGLES, 6, GL::#UNSIGNED_INT, 0)
    
    ; second transformation
    ; ---------------------
    
    ; create transformations
    Protected.f scaleAmount = Sin( sdl::ext_GetElapsedSeconds() ) 
    math::Mat4x4_set(transform, math::m4_1); make sure to initialize matrix to identity matrix first
    math::translate_float(transform, transform, -0.5, 0.5, 0.0); use floats instead of vectors
    math::scale_float(transform, transform, scaleAmount, scaleAmount, scaleAmount); dito
    
    ; get matrix's uniform location and set matrix
    shader::Use(ourShader)
    gl::UniformMatrix4fv(transformLoc, 1, GL::#False, transform); transform has a structure, so transform and @transform is the same
        
    ; render container
    gl::BindVertexArray(VAO)
    gl::DrawElements(GL::#TRIANGLES, 6, GL::#UNSIGNED_INT, 0)
         
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @VAO)
  gl::DeleteBuffers(1, @VBO)
  gl::DeleteBuffers(1, @EBO)
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
EndProcedure



