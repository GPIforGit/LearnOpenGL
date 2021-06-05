DeclareModule texture
  EnableExplicit
  
  ; load a texture and return openGL-ID. 
  ; optimization to make sure textures aren't loaded more than once.
  Declare.l Load(path.s)
  
  ; free a texture
  Declare.l Delete(id.l)
  
  ; return the path of the file
  Declare.s GetFile(id.l)
  
EndDeclareModule

Module texture
  ; real loading routine
  Declare.l _Load(path.s)
  
  ; Texture-Cache
  Structure sTextures_loaded
    id.l
    count.l
  EndStructure  
  Global NewMap textures_loaded.sTextures_loaded()
  
  Procedure.l Load(path.s)
    ; already cached?
    If FindMapElement( textures_loaded(), path)
      textures_loaded()\count +1 ; add reference
      ProcedureReturn textures_loaded()\id      
    EndIf
    
    ; new entry
    textures_loaded( path )
    textures_loaded()\id = _load(path)
    textures_loaded()\count = 1
    ProcedureReturn textures_loaded()\id
  EndProcedure
  
  Procedure.l Delete(id.l)
    ForEach textures_loaded()
      
      If textures_loaded()\id = id
        textures_loaded()\count - 1
        If textures_loaded()\count <= 0 ; last reference?
          ; delete reference
          gl::DeleteTextures( 1, @ textures_loaded()\id )
          DeleteMapElement(textures_loaded())          
        EndIf
        ProcedureReturn
      EndIf
      
    Next
  EndProcedure  
  
  Procedure.s GetFile(id.l)
    ForEach textures_loaded()
      
      If textures_loaded()\id = id        
        ProcedureReturn MapKey( textures_loaded() )
      EndIf
      
    Next
    ProcedureReturn ""; not handled by this module
  EndProcedure
  
  
  ; utility function for loading a 2D texture from file
  ; ---------------------------------------------------
  Procedure.l _Load(path.s)
    Protected.l textureID
    gl::GenTextures(1, @textureID)
    
    Protected.sdl::surface  *surface = sdl::img_load( path )
    If *surface = #Null
      Debug "Texture failed to load at path: " + path
      gl::DeleteTextures(1, @TextureID)
      ProcedureReturn #Null
    EndIf
    
    Protected.l format
    If *surface\format\format = sdl::#PIXELFORMAT_RGB24
      format = gl::#RGB
    ElseIf *surface\format\format = sdl::#PIXELFORMAT_RGBA32
      format = gl::#RGBA
    Else
      Protected.sdl::Surface *convertSurface
      If sdl::ISPIXELFORMAT_ALPHA( *surface\format\format )
        *convertSurface = sdl::ConvertSurfaceFormat( *surface, sdl::#PIXELFORMAT_RGBA32,0)
        format = gl::#RGBA
      Else
        *convertSurface = sdl::ConvertSurfaceFormat( *surface, sdl::#PIXELFORMAT_RGB24,0)
        format = gl::#RGB
      EndIf
      sdl::FreeSurface( *surface )
      *surface = *convertSurface
    EndIf
    
    ; openGL need vertical fliped textures
    sdl::ext_Surface_FlipVertical(*surface)
    
    gl::BindTexture(GL::#TEXTURE_2D, textureID)
    gl::TexImage2D(GL::#TEXTURE_2D, 0, format, *surface\w, *surface\h, 0, format, GL::#UNSIGNED_BYTE, *surface\pixels)
    gl::GenerateMipmap(GL::#TEXTURE_2D)
    
    gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_S, GL::#REPEAT)
    gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_WRAP_T, GL::#REPEAT)
    gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MIN_FILTER, GL::#LINEAR_MIPMAP_LINEAR)
    gl::TexParameteri(GL::#TEXTURE_2D, GL::#TEXTURE_MAG_FILTER, GL::#LINEAR)
    
    sdl::FreeSurface( *surface )
    
    ProcedureReturn TextureID
  EndProcedure
EndModule

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 10
; Folding = --
; EnableXP