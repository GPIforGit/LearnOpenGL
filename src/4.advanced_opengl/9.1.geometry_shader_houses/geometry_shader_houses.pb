EnableExplicit

; https://learnopengl.com/Advanced-OpenGL/Geometry-Shader

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
;XIncludeFile "../../../common/camera.pbi"
XIncludeFile "../../../common/window.pbi"
;XIncludeFile "../../../common/texture.pbi"
;XIncludeFile "../../../common/model.pbi"

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

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
  Protected.l Shader = shader::new("geometry_shader.vs", "geometry_shader.fs", "geometry_shader.gs")
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    points:
    Data.f -0.5,  0.5, 1.0, 0.0, 0.0, ; top-left
           0.5,  0.5, 0.0, 1.0, 0.0,  ; top-right
           0.5, -0.5, 0.0, 0.0, 1.0,  ; bottom-right
           -0.5, -0.5, 1.0, 1.0, 0.0  ; bottom-left
    pointsEnd:
    
  EndDataSection
  
  Protected.l VBO, VAO
    gl::GenBuffers(1, @VBO)
    gl::GenVertexArrays(1, @VAO)
    gl::BindVertexArray(VAO)
    gl::BindBuffer(GL::#ARRAY_BUFFER, VBO);
    gl::BufferData(GL::#ARRAY_BUFFER, ?pointsEnd-?points, ?points, GL::#STATIC_DRAW)
    gl::EnableVertexAttribArray(0)
    gl::VertexAttribPointer(0, 2, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 0)
    gl::EnableVertexAttribArray(1)
    gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 2 * SizeOf(float))
    gl::BindVertexArray(0)
  
  ;- render loop  
  ;  -----------
  While Not window::ShouldClose()
    
    ; window size changed
    ; -------------------
    If window::HasResized()
      gl::Viewport(0,0, window::GetWidth(), window::GetHeight())           
    EndIf
    
    ; render
    ; ------
    
    gl::ClearColor(0.1, 0.1, 0.1, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT | GL::#DEPTH_BUFFER_BIT)
    
    ; draw points
    shader::use(shader)
    gl::BindVertexArray(VAO)
    gl::DrawArrays(GL::#POINTS, 0, 4)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @VAO)
  gl::DeleteBuffers(1, @VBO)
  
  shader::Delete(Shader)  
  
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





