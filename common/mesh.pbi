XIncludeFile "shaders.pbi"
XIncludeFile "texture.pbi"

DeclareModule Mesh
  EnableExplicit
  Structure Vertex
    Position.math::vec3
    Normal.math::vec3
    texCoords.math::vec2
    tangent.math::vec3
    Bitangent.math::vec3
  EndStructure
  
  Enumeration
    #Texture_Diffuse
    #Texture_Specular
    #Texture_Normal
    #Texture_Height
  EndEnumeration  
  
  Structure Texture
    id.l ; openGL id
    type.l; = #texture_* constants
  EndStructure
    
  ; create a mesh-Object. all the "arrays" can be released after this call. the Texture-OpenGL-Id will be handled be this object after this call.
  Declare.i new(*vertices.vertex, verticesSize.l, *indices.long, indicesSize.l, *textures.mesh::Texture, texturesSize.l )
  
  ; release the object and all texture-ids
  Declare delete(*mesh)
  
  ; render the mesh - shader must be active before this call!
  Declare Draw(*mesh, shader.l)
  
EndDeclareModule

Module Mesh
  Structure sMesh
    *textures.texture
    texturesSize.l    
    VAO.l 
    VBO.l
    EBO.l
    indicesSize.l
  EndStructure
  
  ; setup the mesh als own VAO 
  Declare _setupMesh(*mesh.sMesh, *vertices.Vertex, verticesSize.l, *indices.long, indicesSize.l)
  
  Procedure.i new(*vertices.vertex, verticesSize.l, *indices.long, indicesSize.l, *textures.mesh::Texture, texturesSize.l )
    Protected.sMesh *ret = AllocateStructure(sMesh)
    Protected.l i
    
    *ret\indicesSize = indicesSize
    
    ; copy the textures-Array
    *ret\textures = AllocateMemory( texturesSize * SizeOf(Texture) )
    *ret\texturesSize = texturesSize    
    CopyMemory(*textures, *ret\textures, texturesSize)
       
    _setupMesh(*ret, *vertices, verticesSize, *indices, indicesSize)    
    ProcedureReturn *ret
  EndProcedure
  
  Procedure delete(*mesh.sMesh)
    Protected.l i
    Protected.texture *cTexture = *mesh\textures
    ; free all textures
    For i=0 To *mesh\texturesSize -1   
      texture::Delete( *cTexture\id )
      *cTexture + SizeOf(Texture)
    Next
    ; free buffers
    gl::DeleteVertexArrays(1, @*mesh\VAO)
    gl::DeleteBuffers(1, @*mesh\VBO)
    gl::DeleteBuffers(1, @*mesh\EBO)    
    
    ;free object
    FreeStructure( *mesh )    
  EndProcedure
  
  Procedure Draw(*mesh.sMesh, shader.l)
    ; bind appropriate textures
    Protected.l diffuseNb  = 0
    Protected.l specularNb = 0
    Protected.l normalNb   = 0
    Protected.l heightNb   = 0
    Protected.l i = 0
    
    ; activate all textures
    Protected.texture *cTexture = *mesh\textures ; current texture
    For i=0 To *mesh\texturesSize -1
      gl::ActiveTexture(gl::#texture0 + i)
      
      ; retrieve texture number (the N in diffuse_textureN)
      Protected.s name
      Select *cTexture\type
        Case #Texture_Diffuse
          diffuseNb +1
          name = "texture_diffuse" + diffuseNb
        Case #texture_specular
          specularNb +1
          name = "texture_specular" + specularNb
        Case #texture_normal
          normalNb +1
          name = "texture_normal" + normalNb
        Case #texture_height
          heightNb +1
          name = "texture_height" + heightNb
      EndSelect
      
      ; now set the sampler to the correct texture unit
      gl::Uniform1i(gl::GetUniformLocation(shader, name ), i)
      
      ; and finally bind the texture
      gl::BindTexture(GL::#TEXTURE_2D, *cTexture\id)
            
      *cTexture + SizeOf(texture)
    Next
    
    ; draw mesh
    gl::BindVertexArray(*mesh\VAO)
    gl::DrawElements(GL::#TRIANGLES, *mesh\indicesSize , GL::#UNSIGNED_INT, 0)
    gl::BindVertexArray(0)      
        
    ;always good practice zo set everything back zo defaults once configured.
    gl::ActiveTexture(GL::#TEXTURE0)
            
  EndProcedure
  
  Procedure _setupMesh(*mesh.sMesh, *vertices.Vertex, verticesSize.l, *indices.long, indicesSize.l)   
    ; create buffers/arrays
    gl::GenVertexArrays(1, @ *mesh\VAO)
    gl::GenBuffers(1, @ *mesh\VBO)
    gl::GenBuffers(1, @ *mesh\EBO)
    
    gl::BindVertexArray(*mesh\VAO)
    ; load data into vertex buffers
    gl::BindBuffer(GL::#ARRAY_BUFFER, *mesh\VBO)
    
    ; A great thing about structs is that their memory layout is sequential for all its items.
    ; The effect is that we can simply pass a pointer To the struct and it translates perfectly To a glm::vec3/2 Array which
    ; again translates to 3/2 floats which translates to a byte array.
    gl::BufferData(GL::#ARRAY_BUFFER, verticesSize * SizeOf(Vertex), *vertices, GL::#STATIC_DRAW)
    
    gl::BindBuffer(GL::#ELEMENT_ARRAY_BUFFER, *mesh\EBO)
    gl::BufferData(GL::#ELEMENT_ARRAY_BUFFER, indicesSize * SizeOf(long), *indices, GL::#STATIC_DRAW)
    
    ; set the vertex attribute pointers
    ; vertex Positions
    gl::EnableVertexAttribArray(0);
    gl::VertexAttribPointer(0, 3, GL::#FLOAT, GL::#False, SizeOf(Vertex), 0);
                                                                            ; vertex normals
    gl::EnableVertexAttribArray(1)
    gl::VertexAttribPointer(1, 3, GL::#FLOAT, GL::#False, SizeOf(Vertex), OffsetOf(Vertex\Normal))
    ; vertex texture coords
    gl::EnableVertexAttribArray(2)
    gl::VertexAttribPointer(2, 2, GL::#FLOAT, GL::#False, SizeOf(Vertex), OffsetOf(Vertex\TexCoords))
    ; vertex tangent
    gl::EnableVertexAttribArray(3)
    gl::VertexAttribPointer(3, 3, GL::#FLOAT, GL::#False, SizeOf(Vertex), OffsetOf(Vertex\Tangent))
    ; vertex bitangent
    gl::EnableVertexAttribArray(4)
    gl::VertexAttribPointer(4, 3, GL::#FLOAT, GL::#False, SizeOf(Vertex), OffsetOf(Vertex\Bitangent))
    
    gl::BindVertexArray(0)
  EndProcedure
  
  
EndModule
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 124
; FirstLine = 130
; Folding = --
; EnableXP