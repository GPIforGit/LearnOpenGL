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
  Protected.l Shader = shader::new("instancing.vs", "instancing.fs")
  
  ; generate a list of 100 quad locations/translation-vectors
  ; ---------------------------------------------------------
  Dim translations.math::vec2(99)
  Protected.l index, y, x
  Protected.f offset = 0.1
  For y = -10 To 8 Step 2
    For  x = -10 To  8 Step 2
      translations(index)\x = x / 10.0 + offset
      translations(index)\y = y / 10.0 + offset
      index +1
    Next    
  Next
  
  ; store instance data in an array buffer
  ; --------------------------------------
  Protected.l instanceVBO
  gl::GenBuffers(1, @instanceVBO)
  gl::BindBuffer(GL::#ARRAY_BUFFER, instanceVBO)
  gl::BufferData(GL::#ARRAY_BUFFER, SizeOf(math::vec2) * 100, @translations(), GL::#STATIC_DRAW)
  gl::BindBuffer(GL::#ARRAY_BUFFER, 0)
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    quadVertices:
    ;      positions     colors
    Data.f -0.05,  0.05,  1.0, 0.0, 0.0, ;1
           0.05, -0.05,  0.0, 1.0, 0.0,
           -0.05, -0.05,  0.0, 0.0, 1.0,
           -0.05,  0.05,  1.0, 0.0, 0.0, ;2
           0.05, -0.05,  0.0, 1.0, 0.0,
           0.05,  0.05,  0.0, 1.0, 1.0
    quadVerticesEnd:
  EndDataSection
  
  Protected.l quadVBO, quadVAO
  gl::GenBuffers(1, @quadVBO)
  gl::GenVertexArrays(1, @quadVAO)
  gl::BindVertexArray(quadVAO)
  gl::BindBuffer(GL::#ARRAY_BUFFER,quadVBO);
  gl::BufferData(GL::#ARRAY_BUFFER, ?quadVerticesEnd-?quadVertices, ?quadVertices, GL::#STATIC_DRAW)
  gl::EnableVertexAttribArray(0)
  gl::VertexAttribPointer(0, 2, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(1)
  gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, 5 * SizeOf(float), 2 * SizeOf(float))
  ; also set instance data
  gl::EnableVertexAttribArray(2);
  gl::BindBuffer(GL::#ARRAY_BUFFER, instanceVBO); this attribute comes from a different vertex buffer
  gl::VertexAttribPointer(2, 2, GL::#FLOAT, GL::#False, 2 * SizeOf(float), 0)
  gl::BindBuffer(GL::#ARRAY_BUFFER, 0);
  gl::VertexAttribDivisor(2, 1)       ; tell OpenGL this is an instanced vertex attribute.
  
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
    
    ; draw 100 instanced quads
    shader::use(shader)
    gl::BindVertexArray(quadVAO)
    gl::DrawArraysInstanced(GL::#TRIANGLES, 0, 6, 100) ; 100 triangles of 6 vertices each
    gl::BindVertexArray(0)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()  
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @quadVAO)
  gl::DeleteBuffers(1, @quadVBO)
  gl::DeleteBuffers(1, @instanceVBO)
  
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





