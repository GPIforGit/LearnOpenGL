EnableExplicit

; https://learnopengl.com/Getting-started/Shaders

DeclareModule SDL_Config
  ;we want OpenGL-Version 3.3
  #GL_MAJOR_VERSION = 3
  #GL_MINOR_VERSION = 3
  ;sdl2_image
  ;#UseImage = #True
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

Global.f offset = 0.5

Procedure main()
  ; initialize sdl, opengl and open a window
  ; ----------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH, #SCR_HEIGHT )
    End
  EndIf
    
  ; build and compile our shader program
  ; ------------------------------------
  Protected.l ourShader = shader::new("shader.vs", "shader.fs")
    
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    vertices:
    ;      positions         colors
    Data.f 0.5, -0.5, 0.0,   1.0, 0.0, 0.0,  ; bottom right
           -0.5, -0.5, 0.0,  0.0, 1.0, 0.0, ; bottom left
           0.0,  0.5, 0.0,   0.0, 0.0, 1.0   ; top 
    vertices_end:
  EndDataSection
  
  Protected.l VBO, VAO
  gl::GenVertexArrays(1, @VAO)
  gl::GenBuffers(1, @VBO)
  ; bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
  gl::BindVertexArray(VAO)
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?vertices_end - ?vertices, ?vertices, GL::#STATIC_DRAW)
  
  ; position attribute
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(0)
  ; color attribute    
  gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, 6 * SizeOf(float), 3 * SizeOf(float))
  gl::EnableVertexAttribArray(1)
        
  ; You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
  ; VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
  ; gl::BindVertexArray(0)  

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
       
    ; render the triangle
    shader::Use(ourShader)
    shader::setFloat(ourShader,"xOffset", offset)    
    gl::BindVertexArray(VAO)
    gl::DrawArrays(GL::#TRIANGLES, 0, 3)
    
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
    window::SetShouldClose( #True )
  EndIf   
EndProcedure



