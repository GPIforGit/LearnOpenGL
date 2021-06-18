; changes
; - merge of the shader.h, shader_m.h and shader_s.h 
; - delete() for cleanup

DeclareModule Shader
  EnableExplicit
  
  ; read the shader files, compile and link. Return ProgrammId
  Declare.l new(vertexPath.s, fragmentPath.s, geometryPath.s="")
  
  ; use programm
  Declare Use(id)
  
  ; remove programm
  Declare delete(id.l)
  
  ; set unicode variables
  Declare setBool(id.l, name.s, value.l)
  Declare setInt(id.l, name.s, value.l)
  Declare setFloat(id.l, name.s, value.f)
  
  ; from shaders_m.h
  CompilerIf Defined(math,#PB_Module)
    Declare setVec2(id.l, name.s, *value)
    Declare setVec2_float(id.l, name.s, x.f, y.f)
    Declare setVec3(id.l, name.s, *value)
    Declare setVec3_float(id.l, name.s, x.f, y.f, z.f)
    Declare setVec4(id.l, name.s, *value)
    Declare setVec4_float(id.l, name.s, x.f, y.f, z.f, w.f)
    Declare setMat2x2(id.l, name.s, *mat)
    Declare setMat3x3(id.l, name.s, *mat)
    Declare setMat4x4(id.l, name.s, *mat)
  CompilerEndIf  
  
EndDeclareModule

Module Shader 
  
  ; check for errors while compiling or linking
  Declare _checkCompileErrors(shader.l, type.s, file.s="")
  
  
  Procedure Use(id)
    gl::UseProgram(ID)
  EndProcedure 
  
  Procedure setBool(id.l, name.s, value.l)
    gl::Uniform1i(gl::GetUniformLocation(ID, name), value)
  EndProcedure
  Procedure setInt(id.l, name.s, value.l)
    gl::Uniform1i(gl::GetUniformLocation(ID, name), value)
  EndProcedure
  Procedure setFloat(id.l, name.s, value.f)
    gl::Uniform1f(gl::GetUniformLocation(ID, name), value)
  EndProcedure
  
  CompilerIf Defined(math,#PB_Module)
    Procedure setVec2(id.l, name.s, *value)  
      gl::Uniform2fv( gl::GetUniformLocation(ID, name), 1, *value)
    EndProcedure
    
    Procedure setVec2_float(id.l, name.s, x.f, y.f)
      gl::Uniform2f( gl::GetUniformLocation(ID, name), x, y)
    EndProcedure
    
    Procedure setVec3(id.l, name.s, *value)
      gl::Uniform3fv( gl::GetUniformLocation(ID, name), 1, *value)
    EndProcedure
    
    Procedure setVec3_float(id.l, name.s, x.f, y.f, z.f)
      gl::Uniform3f(  gl::GetUniformLocation(ID, name), x, y, z)
    EndProcedure
    
    Procedure setVec4(id.l, name.s, *value) 
      gl::Uniform4fv( gl::GetUniformLocation(ID, name), 1, *value) 
    EndProcedure
    
    Procedure setVec4_float(id.l, name.s, x.f, y.f, z.f, w.f)
      gl::Uniform4f( gl::GetUniformLocation(ID, name), x, y, z, w)
    EndProcedure
    
    Procedure setMat2x2(id.l, name.s, *mat)
      gl::UniformMatrix2fv( gl::GetUniformLocation(ID, name), 1, GL::#False, *mat)
    EndProcedure
    
    Procedure setMat3x3(id.l, name.s, *mat)
      gl::UniformMatrix3fv( gl::GetUniformLocation(ID, name), 1, GL::#False, *mat)
    EndProcedure
    
    Procedure setMat4x4(id.l, name.s, *mat)
      gl::UniformMatrix4fv( gl::GetUniformLocation(ID, name), 1, GL::#False, *mat)
    EndProcedure
          
  CompilerEndIf
    
  Procedure delete(id.l)
    gl::DeleteProgram(id)
  EndProcedure  
     
  Procedure.l new(vertexPath.s, fragmentPath.s, geometryPath.s="")
    Protected.l id
    ;1. retrieve the vertex/fragment source code from filePath
    Protected in
    Protected *vShaderCode, *fShaderCode, *gShaderCode
    in = ReadFile(#PB_Any, vertexPath)
    If in
      *vShaderCode = AllocateMemory( Lof(in) +1) ; add a zero at the end
      ReadData(in, *vShaderCode, Lof(in) )
      ;PokeB(*vShaderCode + Lof(in),#LF) ; add a line-end-marker
      CloseFile(in)
    Else
      Debug "ERROR::SHADER::FILE_NOT_SUCCESFULLY_READ"
      Debug vertexPath
      CallDebugger
    EndIf
    
    in = ReadFile(#PB_Any, fragmentPath)
    If in
      *fShaderCode = AllocateMemory( Lof(in)+1 ); add a zero at the end
      ReadData(in, *fShaderCode, Lof(in) )
      ;PokeB(*vShaderCode + Lof(in),#LF) ; add a line-end-marker
      CloseFile(in)
    Else
      Debug "ERROR::SHADER::FILE_NOT_SUCCESFULLY_READ"
      Debug fragmentPath
      CallDebugger
    EndIf
    
    If geometryPath<>""
      in = ReadFile(#PB_Any, geometryPath)
      If in
        *gShaderCode = AllocateMemory( Lof(in)+1 ); add a zero at the end
        ReadData(in, *gShaderCode, Lof(in) )
        ;PokeB(*vShaderCode + Lof(in),#LF) ; add a line-end-marker
        CloseFile(in)
      Else
        Debug "ERROR::SHADER::FILE_NOT_SUCCESFULLY_READ"
        Debug geometryPath
        CallDebugger
      EndIf
    EndIf
        
    Protected.l vertex, fragment, geometry
    ; vertex shader
    vertex = gl::CreateShader(GL::#VERTEX_SHADER)
    gl::ShaderSource(vertex, 1, @ *vShaderCode, #Null)
    gl::CompileShader(vertex)
    _checkCompileErrors(vertex, "VERTEX", vertexPath)
    ; fragment Shader
    fragment = gl::CreateShader(GL::#FRAGMENT_SHADER)
    gl::ShaderSource(fragment, 1, @ *fShaderCode, #Null)
    gl::CompileShader(fragment)
    _checkCompileErrors(fragment, "FRAGMENT",fragmentPath)
    ; if geometry shader is given, compile geometry shader
    If *gShaderCode
      geometry = gl::CreateShader(gl::#GEOMETRY_SHADER)
      gl::ShaderSource(geometry, 1, @ *gShaderCode, #Null)
      gl::CompileShader(geometry)
      _checkCompileErrors(geometry, "GEOMETRY", geometryPath)
    EndIf    
    ; shader Program
    ID = gl::CreateProgram()
    gl::AttachShader(ID, vertex)
    gl::AttachShader(ID, fragment)
    If *gShaderCode
      gl::AttachShader(ID, geometry)
    EndIf
    gl::LinkProgram(ID)
    _checkCompileErrors(ID, "PROGRAM")
    ; delete the shaders as they're linked into our program now and no longer necessary
    gl::DeleteShader(vertex)
    gl::DeleteShader(fragment)
    If *gShaderCode
      gl::DeleteShader(geometry)
    EndIf
    
    FreeMemory(*fShaderCode)
    FreeMemory(*vShaderCode)
    If *gShaderCode
      FreeMemory(*gShaderCode)
    EndIf
    
    ProcedureReturn id
  EndProcedure
  
  Procedure _checkCompileErrors(shader.l, type.s, file.s ="")
    Protected.l success
    Protected *infolog = AllocateMemory(1024)  
    
    If type <> "PROGRAM"
      gl::GetShaderiv(shader, GL::#COMPILE_STATUS, @success)
    Else
      gl::GetProgramiv(shader, GL::#LINK_STATUS, @success)
    EndIf
    
    If Not success
      gl::GetShaderInfoLog(shader, 1024, #Null, *infoLog)
      Debug "ERROR::SHADER::" + type + "::FAILED "+file      
      Debug PeekS(*infolog, 512, #PB_UTF8 | #PB_ByteLength)
      CallDebugger
    EndIf
    
  EndProcedure
  
EndModule
