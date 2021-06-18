EnableExplicit

; https://learnopengl.com/Getting-started/Textures

; CHANGES
; learnopengl/filesystem.h - removed, we use relativ path here. linux-style works on windows too :)
; stb_image.h is replaced by SDL_Image
; set GL::#TEXTURE_MIN_FILTER to GL::#LINEAR_MIPMAP_LINEAR - we created mipmaps and should use them

DeclareModule SDL_Config
  ;we want OpenGL-Version 3.3
  #GL_MAJOR_VERSION = 3
  #GL_MINOR_VERSION = 3
  ;sdl2_image
  #UseImage = #True
EndDeclareModule

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"
XIncludeFile #PB_Compiler_Home + "Include/sdl2/opengl.pbi"
;XIncludeFile #PB_Compiler_Home + "Include/math/math.pbi"
XIncludeFile "../../../common/shaders.pbi"
XIncludeFile "../../../common/window.pbi"

Declare processInput()

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

Procedure main()
  ; initialize sdl, opengl and open a window (sdl_stuff)
  ; ----------------------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH,#SCR_HEIGHT, sdl::#INIT_VIDEO | sdl::#INIT_EVENTS | sdl::#INIT_TIMER, sdl::#IMG_INIT_JPG | sdl::#IMG_INIT_PNG )
    End
  EndIf
  
  ; build and compile our shader program
  ; ------------------------------------
  Protected.l ourShader = shader::new("texture.vs", "texture.fs")
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    vertices:
    ;      positions          colors           texture coords
    Data.f 00.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0, ; top right
           00.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0, ; bottom right
           -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0, ; bottom left
           -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0  ; top left 
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
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 8 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(0)
  ; color attribute    
  gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, 8 * SizeOf(float), 3 * SizeOf(float))
  gl::EnableVertexAttribArray(1)
  ; texture coord attribute
  gl::VertexAttribPointer(2, 2, GL::#FLOAT, GL::#False, 8 * SizeOf(float), 6 * SizeOf(float))
  gl::EnableVertexAttribArray(2)
  
  ; load and create a texture 
  ; -------------------------
  Protected.l texture
  gl::GenTextures(1, @texture);
  gl::BindTexture(GL::#TEXTURE_2D, texture); all upcoming GL_TEXTURE_2D operations now have effect on this texture object
                                           ; set the texture wrapping parameters
  gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_S, GL::#REPEAT) ; set texture wrapping to GL_REPEAT (default wrapping method)
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
  
  ;- render loop  
  ;  -----------
  While Not window::ShouldClose()

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
    
    gl::ClearColor(0.2, 0.3, 0.3, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT)
    
    ; bind Texture
    gl::BindTexture(GL::#TEXTURE_2D, texture)
    
    ; render container
    shader::Use(ourShader)
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
    window::SetShouldClose( #True )
  EndIf   
EndProcedure



