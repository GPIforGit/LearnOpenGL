EnableExplicit

; https://learnopengl.com/Getting-started/Hello-Triangle

; changes

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

Global.s fragmentShader1Source = "#version 330 core" + #LF$ +
                                "out vec4 FragColor;" + #LF$ +
                                "void main()" + #LF$ +
                                "{" + #LF$ +
                                "   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);" + #LF$ +
                                "}" + #LF$

Global.s fragmentShader2Source = "#version 330 core" + #LF$ +
                                "out vec4 FragColor;" + #LF$ +
                                "void main()" + #LF$ +
                                "{" + #LF$ +
                                "   FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);" + #LF$ +
                                "}" + #LF$

Procedure main()
  ; initialize sdl, opengl and open a window
  ; ----------------------------------------
  If Not window::init( window::CreateTitle(), #SCR_WIDTH, #SCR_HEIGHT )
    End
  EndIf
  
  ; build and compile our shader program
  ; ------------------------------------
  
  ; we skipped compile log checks this time for readability (if you do encounter issues, add the compile-checks! see previous code samples)
  
  ; vertex shader
  Protected.l vertexShader = gl::CreateShader(GL::#VERTEX_SHADER)
  Protected.l fragmentShaderOrange = gl::CreateShader(GL::#FRAGMENT_SHADER)
  Protected.l fragmentShaderYellow = gl::CreateShader(GL::#FRAGMENT_SHADER)
  Protected.l shaderProgramOrange = gl::CreateProgram()
  Protected.l shaderProgramYellow = gl::CreateProgram()
  
  Protected *vertexShaderSource = UTF8(vertexShaderSource) ; we need a pointer to a utf8 string
  gl::ShaderSource(vertexShader, 1, @ *vertexShaderSource, #Null)
  gl::CompileShader(vertexShader)
    
  Protected *fragmentShaderSourceOrange = UTF8(fragmentShader1Source) ; we need a pointer to a utf8 string
  gl::ShaderSource(fragmentShaderOrange, 1, @ *fragmentShaderSourceOrange, #Null)
  gl::CompileShader(fragmentShaderOrange)
    
  Protected *fragmentShaderSourceYellow = UTF8(fragmentShader2Source) ; we need a pointer to a utf8 string
  gl::ShaderSource(fragmentShaderYellow, 1, @ *fragmentShaderSourceYellow, #Null)
  gl::CompileShader(fragmentShaderYellow)
      
  ; link the first program object
  gl::AttachShader(shaderProgramOrange, vertexShader)
  gl::AttachShader(shaderProgramOrange, fragmentShaderOrange)
  gl::LinkProgram(shaderProgramOrange)
    
  ; then link the second program object using a different fragment shader (but same vertex shader)
  ; this is perfectly allowed since the inputs and outputs of both the vertex and fragment shaders are equally matched.
  gl::AttachShader(shaderProgramYellow, vertexShader)
  gl::AttachShader(shaderProgramYellow, fragmentShaderYellow)
  gl::LinkProgram(shaderProgramYellow)
    
  gl::DeleteShader(vertexShader)
  gl::DeleteShader(fragmentShaderOrange)
  gl::DeleteShader(fragmentShaderYellow)

  FreeMemory(*vertexShaderSource) : *vertexShaderSource = #Null
  FreeMemory(*fragmentShaderSourceOrange) : *fragmentShaderSourceOrange = #Null
  FreeMemory(*fragmentShaderSourceYellow) : *fragmentShaderSourceYellow = #Null
    
  ; set up vertex data (and buffer(s)) and configure vertex attributes
  ; ------------------------------------------------------------------
  DataSection
    firstTriangle:
    ; first triangle
    Data.f -0.9, -0.5, 0.0,  ; left 
           -0.0, -0.5, 0.0,  ; right
           -0.45, 0.5, 0.0   ; top 
    firstTriangle_end:
    secondTriangle:
    ; second triangle
    Data.f 0.0, -0.5, 0.0, ; left
           0.9, -0.5, 0.0, ; right
           0.45, 0.5, 0.0  ; top 
    secondTriangle_end:
  EndDataSection
  
  Structure LongArray2
    l.l[2]
  EndStructure
  Protected.LongArray2 VBOs, VAOs
  gl::GenVertexArrays(2, VAOs); we can also generate multiple VAOs or buffers at the same time
  gl::GenBuffers(2, VBOs)
  
  ; first triangle setup
  ; --------------------
  gl::BindVertexArray(VAOs\l[0])
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBOs\l[0])
  gl::BufferData(GL::#ARRAY_BUFFER, ?firstTriangle_end - ?firstTriangle, ?firstTriangle, GL::#STATIC_DRAW)
  
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 3 * SizeOf(float), 0); Vertex attributes stay the same
  gl::EnableVertexAttribArray(0)
  
  ;gl::BindBuffer(GL::#ARRAY_BUFFER, 0) ;no need to unbind at all as we directly bind a different VAO the next few lines
  
  ; second triangle setup
  ; ---------------------
  gl::BindVertexArray(VAOs\l[1]) ; note that we bind to a different VAO now
  
  gl::BindBuffer(GL::#ARRAY_BUFFER, VBOs\l[1]); and a different VBO
  gl::BufferData(GL::#ARRAY_BUFFER, ?secondTriangle_end - ?secondTriangle, ?secondTriangle, GL::#STATIC_DRAW) ;
  
  gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, 0, 0); because the vertex data is tightly packed we can also specify 0 as the vertex attribute's stride to let OpenGL figure it out
  gl::EnableVertexAttribArray(0)
    
  ; You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
  ; VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
  gl::BindVertexArray(0)
    
  ; uncomment this call to draw in wireframe polygons.
  ; gl::PolygonMode(GL::#FRONT_AND_BACK, GL::#LINE)
    
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
        
    ; now when we draw the triangle we first use the vertex and orange fragment shader from the first program
    gl::UseProgram(shaderProgramOrange)
    ; draw the first triangle using the data from our first VAO
    gl::BindVertexArray(VAOs\l[0])
    gl::DrawArrays(GL::#TRIANGLES, 0, 6) ; this call should output an orange triangle
    
    ; then we draw the second triangle using the data from the second VAO
    ; when we draw the second triangle we want to use a different shader program so we switch to the shader program with our yellow fragment shader.
    gl::UseProgram(shaderProgramYellow)
    gl::BindVertexArray(VAOs\l[1])
    gl::DrawArrays(GL::#TRIANGLES, 0, 6) ; this call should output a yellow triangle
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    ; -------------------------------------------------------------------------
    window::SwapBuffers()
    window::PollEvents()
    
    
  Wend
  
  ; optional: de-allocate all resources once they've outlived their purpose:
  ; ------------------------------------------------------------------------
  gl::DeleteVertexArrays(2, VAOs)
  gl::DeleteBuffers(2, VBOs)
  gl::DeleteProgram(shaderProgramOrange)
  gl::DeleteProgram(shaderProgramYellow)
  
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


