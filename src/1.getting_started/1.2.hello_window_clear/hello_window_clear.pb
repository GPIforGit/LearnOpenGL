EnableExplicit

; https://learnopengl.com/Getting-started/Hello-Window

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

Procedure main()
  Protected.l i
  
  ; initialize sdl, opengl and open a window 
  ; ----------------------------------------
  If Not window::init(window::CreateTitle(), #SCR_WIDTH, #SCR_HEIGHT)
    End
  EndIf
  
  
  ;- render loop  
  ;  -----------
  While Not window::WindowShouldClose()
    
    ; input
    ; -----
    processInput()
    
    ; render
    gl::ClearColor(0.2, 0.3, 0.3, 1.0)
    gl::Clear(GL::#COLOR_BUFFER_BIT)
    
    ; Swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
    window::SwapBuffers()
    window::PollEvents()
    
  Wend
  
  ; terminate, clearing all previously allocated resources
  window::quit()
EndProcedure
main()


; process all input: query whether relevant keys are pressed/released this frame and react accordingly
Procedure processInput()
  If window::GetKey( sdl::#SCANCODE_ESCAPE )
    window::SetWindowShouldClose( #True )
  EndIf   
EndProcedure

