﻿EnableExplicit

; https://learnopengl.com/Getting-started/Hello-Triangle

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
XIncludeFile  "../../../common/window.pbi"

Declare processInput()

;- settings

#SCR_WIDTH = 800
#SCR_HEIGHT = 600

Global.s vertexShaderSource = "#version 330 core" + #LF$ +
                              "layout (location = 0) in vec3 aPos;" + #LF$ +
                              "void main()" + #LF$ +
                              "{" + #LF$ +
                              "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);" + #LF$ +
                              "}" + #LF$

Global.s fragmentShaderSource = "#version 330 core" + #LF$ +
                                "out vec4 FragColor;" + #LF$ +
                                "void main()" + #LF$ +
                                "{" + #LF$ +
                                "   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);" + #LF$ +
                                "}" + #LF$

Procedure main()

  ; initialize sdl, opengl and open a window 
  ; ----------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH, #SCR_HEIGHT )
    End
  EndIf
  
  ; build and compile our shader program
  ; ------------------------------------
  
  ; vertex shader
  Protected.l vertexShader = gl::CreateShader(GL::#VERTEX_SHADER)
  Protected *vertexShaderSource = UTF8(vertexShaderSource) ; we need a pointer to a utf8 string
  gl::ShaderSource(vertexShader, 1, @ *vertexShaderSource, #Null)
  gl::CompileShader(vertexShader)
  
  ; check for shader compile errors
  Protected.l success
  Protected *infolog = AllocateMemory(512);
  gl::GetShaderiv(vertexShader, GL::#COMPILE_STATUS, @success)
  If Not success
    gl::GetShaderInfoLog(vertexShader, 512, #Null, *infoLog)
    Debug "ERROR::SHADER::VERTEX::COMPILATION_FAILED"
    Debug PeekS(*infolog, 512, #PB_UTF8 | #PB_ByteLength)
  EndIf
  
  ; fragment shader
  Protected.l fragmentShader = gl::CreateShader(GL::#FRAGMENT_SHADER)
  Protected *fragmentShaderSource = UTF8(fragmentShaderSource) ; we need a pointer to a utf8 string
  gl::ShaderSource(fragmentShader, 1, @ *fragmentShaderSource, #Null)
  gl::CompileShader(fragmentShader)
  
  ; check for shader compile errors
  gl::GetShaderiv(fragmentShader, GL::#COMPILE_STATUS, @success)
  If Not success
    gl::GetShaderInfoLog(fragmentShader, 512, #Null, *infoLog)
    Debug "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED"
    Debug PeekS(*infolog, 512, #PB_UTF8 | #PB_ByteLength)
  EndIf
  
  ; link shaders
  Protected.l shaderProgram = gl::CreateProgram()
  gl::AttachShader(shaderProgram, vertexShader)
  gl::AttachShader(shaderProgram, fragmentShader)
  gl::LinkProgram(shaderProgram)
  
  ; check for linking errors
  gl::GetProgramiv(shaderProgram, GL::#LINK_STATUS, @success)
  If Not success
    gl::GetProgramInfoLog(shaderProgram, 512, #Null, *infoLog)
    Debug "ERROR::SHADER::PROGRAM::LINKING_FAILED"
    Debug PeekS(*infolog, 512, #PB_UTF8 | #PB_ByteLength)
  EndIf
  
  gl::DeleteShader(vertexShader)
  gl::DeleteShader(fragmentShader)
  FreeMemory(*infolog) : *infolog = #Null
  FreeMemory(*vertexShaderSource) : *vertexShaderSource = #Null
  FreeMemory(*fragmentShaderSource) : *fragmentShaderSource = #Null
  
  
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    vertices:
    ; first triangle
    Data.f    -0.9, -0.5, 0.0,  ; left 
              -0.0, -0.5, 0.0,  ; right
              -0.45, 0.5, 0.0   ; top 
                                ; second triangle
    Data.f         0.0, -0.5, 0.0, ; left
                   0.9, -0.5, 0.0, ; right
                   0.45, 0.5, 0.0  ; top 
    vertices_end:
  EndDataSection
  
  Protected.l VBO, VAO
  gl::GenVertexArrays(1, @VAO)
  gl::GenBuffers(1, @VBO)
  ; bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
  gl::BindVertexArray(VAO)
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBO)
  gl::BufferData(GL::#ARRAY_BUFFER, ?vertices_end - ?vertices, ?vertices, GL::#STATIC_DRAW)
  
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 3 * SizeOf(float), 0)
  gl::EnableVertexAttribArray(0)
  
  ; note that this is allowed, the call To glVertexAttribPointer registered VBO As the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
  gl::BindBuffer(GL::#ARRAY_BUFFER, 0)
  
  ; You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
  ; VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
  gl::BindVertexArray(0)
  
  
  ; uncomment this call to draw in wireframe polygons.
  ; gl::PolygonMode(GL::#FRONT_AND_BACK, GL::#LINE)
  
  
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
    
    ;draw our first triangle
    gl::UseProgram(shaderProgram)
    gl::BindVertexArray(VAO);  seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
    gl::DrawArrays(GL::#TRIANGLES, 0, 6); set the count to 6 since we're drawing 6 vertices now (2 triangles); not 3!
    ;gl::BindVertexArray(0); // no need to unbind it every time 
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(1, @VAO)
  gl::DeleteBuffers(1, @VBO)
  gl::DeleteProgram(shaderProgram)
  
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


