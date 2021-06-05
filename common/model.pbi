
XIncludeFile "shaders.pbi"
XIncludeFile "mesh.pbi"

DeclareModule model
  EnableExplicit
  
  ; loads a model with supported ASSIMP extensions from file and stores the resulting meshes in the meshes vector.
  Declare.i new( path.s)
  
  ; destroy model
  Declare delete( *model ) 
  
  ; draws the model, and thus all its meshes
  Declare Draw( *model, Shader.l)
  
EndDeclareModule

Module model
  Structure sMesh
    i.i ; id for the mesh (in fact it is a pointer)
  EndStructure
  Structure sModel
    *meshes.sMesh ; pointer to an array with Mesh-Ids
    meshesSize.l    ; size of this array
    directory.s     ; directory where the textures should be
  EndStructure
  
  
  
  ; processes a node in a recursive fashion. Processes each individual mesh located at the node and repeats this process on its children nodes (if any).
  ; fills the *mesh-Array
  Declare.i _processNode(*model.sModel, *node.ai::Node, *scene.ai::Scene, *cmesh.sMesh)
  
  ; counts how many nodes in the model exist (recursive).
  Declare.l _countNode(*model.sModel, *node.ai::Node)
  
  ; convert the mesh-data and create a mesh-object
  Declare _processMesh(*model, *mesh.ai::Mesh, *scene.ai::Scene)
  
  ; load the textures and fill the *Texture-Array 
  Declare.i _loadMaterialTextures(*model.sModel, *mat.ai::Material, aiType.l, texType.l, *cTextures.mesh::Texture)
  
  
  Procedure.i new( path.s)
    Protected.sModel *ret
    ; Read file via ASSIMP
    Protected.ai::Scene *scene
    
    *scene = ai::ImportFile(path,  ai::#Process_Triangulate | ai::#Process_GenSmoothNormals | ai::#Process_FlipUVs | ai::#Process_CalcTangentSpace )
    ; some more interestings flags for simpler handling
;                                  ai::#Process_OptimizeMeshes | ai::#Process_OptimizeGraph | ai::#Process_SortByPType | ai::#Process_FixInfacingNormals |
;                                  ai::#Process_JoinIdenticalVertices )
    
    ; check for errors
    If *scene=#Null Or *scene\mFlags & ai::#SCENE_FLAGS_INCOMPLETE Or *scene\mRootNode=#Null
      Debug "ERROR::ASSIMP:: " + ai::GetErrorString()
      
      If *scene
        ai::ReleaseImport (*scene)
      EndIf
      ProcedureReturn #Null
    EndIf
    
    ; create model-object
    *ret = AllocateStructure(sModel)
    
    ; retrieve the directory path of the filepath
    *ret\directory = GetPathPart(path.s)
    
    ; create mesh-array - mesh-array end is marked with a #null pointer 
    *ret\meshesSize = _countNode(*ret,*scene\mRootNode)
    *ret\meshes = AllocateMemory( (*ret\meshesSize +1) * SizeOf(sMesh) ); one extra space for #null-pointer
    
    ; process ASSIMP's root node recursively and fill mesh-array
    _processNode(*ret, *scene\mRootNode, *scene, *ret\meshes)
    
    ; cleanup
    ai::ReleaseImport (*scene)
    
    ProcedureReturn *ret
  EndProcedure
  
  Procedure delete( *model.sModel ) 
    Protected.sMesh *cMesh = *model\meshes
    ; release all the meshes
    While *cmesh\i
      mesh::delete( *cMesh\i )
      *cMesh + SizeOf(sMesh)
    Wend
    
    ; release mesh-array
    FreeMemory( *model\meshes )
    
    ; release the object
    FreeStructure(*model)
  EndProcedure
  
  Procedure Draw( *model.sModel, Shader.l)
    Protected.sMesh *cMesh = *model\meshes
    
    ; draw every mesh
    While *cmesh\i
      mesh::draw( *cmesh\i, shader)
      *cMesh + SizeOf(sMesh)
    Wend
  EndProcedure  
  
  Procedure.l _countNode(*model.sModel, *node.ai::Node)
    Protected.l i
    Protected.l count
      
    count =  *node\mNumMeshes
    ; add child nodes
    For i=0 To *node\mNumChildren-1
      count + _countNode(*model, *node\mChildren\n[i])
    Next

    ProcedureReturn count
  EndProcedure
  
  Procedure.i _processNode(*model.sModel, *node.ai::Node, *scene.ai::Scene, *cmesh.sMesh)
    Protected.l i
    
    ; process each mesh located at the current node
    For i = 0 To *node\mNumMeshes -1        
      ; the node object only contains indices to index the actual objects in the scene. 
      ; the scene contains all the data, node is just to keep stuff organized (like relations between nodes).
      Protected.l j = *node\mMeshes\l[i]
      Protected.ai::Mesh *mesh = *scene\mMeshes\m[ j ]
      
      ; process Mesh and store handle in the mesh-array
      *cmesh\i = _processMesh(*model, *mesh, *scene)
      *cmesh + SizeOf(sMesh)

    Next
    
    ; after we've processed all of the meshes (if any) we then recursively process each of the children nodes
    For i = 0 To *node\mNumChildren -1
      *cmesh = _processNode(*model, *node\mChildren\n[i], *scene,*cmesh)
    Next
    
    ; return the current Mesh write position
    ProcedureReturn *cmesh
  EndProcedure
  
  Procedure _processMesh(*model, *mesh.ai::Mesh, *scene.ai::Scene)
    ; Data To fill
    Protected.l verticesSize   
    Protected.mesh::Vertex *vertices 
    Protected.l indicesSize 
    Protected.long *indices 
    Protected.l texturesSize
    Protected.Mesh::Texture *textures
    
    Protected.l i,j
    
    ; walk through each of the mesh's vertices
    
    verticesSize = *mesh\mNumVertices    
    *vertices = AllocateMemory( verticesSize * SizeOf(mesh::Vertex) )
    Protected.mesh::Vertex *cVertices = *vertices ; current write position
    
    For i = 0  To verticesSize -1
      ;positions
      *cVertices\Position\x = *mesh\mVertices\v[i]\x
      *cVertices\Position\y = *mesh\mVertices\v[i]\y
      *cVertices\Position\z = *mesh\mVertices\v[i]\z
      
      ; normals
      If *mesh\mNormals
        *cVertices\Normal\x = *mesh\mNormals\v[i]\x
        *cVertices\Normal\y = *mesh\mNormals\v[i]\y
        *cVertices\Normal\z = *mesh\mNormals\v[i]\z
      EndIf
      
      ; texture coordinates
      If *mesh\mTextureCoords[0] ;does the mesh contain texture coordinates?
        ; a vertex can contain up to 8 different texture coordinates. We thus make the assumption that we won't 
        ; use models where a vertex can have multiple texture coordinates so we always take the first set (0).
        *cVertices\texCoords\x = *mesh\mTextureCoords[0]\v[i]\x 
        *cVertices\texCoords\y = *mesh\mTextureCoords[0]\v[i]\y
      EndIf
      
      ; tangent
      If *mesh\mTangents
        *cVertices\tangent\x = *mesh\mTangents\v[i]\x
        *cVertices\tangent\y = *mesh\mTangents\v[i]\y
        *cVertices\tangent\z = *mesh\mTangents\v[i]\z
      EndIf
      
      ; bitangent
      If *mesh\mBitangents
        *cVertices\Bitangent\x = *mesh\mBitangents\v[i]\x
        *cVertices\Bitangent\y = *mesh\mBitangents\v[i]\y
        *cVertices\Bitangent\z = *mesh\mBitangents\v[i]\z
      EndIf
      
      *cVertices + SizeOf( mesh::Vertex )
    Next
        
    ; now wak through each of the mesh's faces (a face is a mesh its triangle) and retrieve the corresponding vertex indices.
    
    ; count all indices
    indicesSize = 0
    For i = 0  To *mesh\mNumFaces-1
      indicesSize + *mesh\mFaces\f[i]\mNumIndices
    Next
    
    ; create a array
    *indices = AllocateMemory( indicesSize * SizeOf(long) )
    Protected.long *cIndices = *indices ; current write position
    
    For i=0 To *mesh\mNumFaces-1
      Protected.ai::Face *face = *mesh\mFaces\f[i]
      
      For  j = 0 To *face\mNumIndices-1 
        *cIndices\l = *face\mIndices\l[j]
        *cIndices + SizeOf(long)
      Next
    Next
        
    ; process materials
    Protected.ai::Material *material = *scene\mMaterials\m[*mesh\mMaterialIndex]
    
    ; we assume a convention for sampler names in the shaders. Each diffuse texture should be named
    ; as 'texture_diffuseN' where N is a sequential number ranging from 1 To MAX_SAMPLER_NUMBER. 

    ; count how many Textures are there
    texturesSize = ai::GetMaterialTextureCount(*material, ai::#TextureType_DIFFUSE) + 
                  ai::GetMaterialTextureCount(*material, ai::#TextureType_SPECULAR) + 
                  ai::GetMaterialTextureCount(*material, ai::#TextureType_NORMALS) + 
                  ai::GetMaterialTextureCount(*material, ai::#TextureType_HEIGHT)
    
    ; create the textures array
    *textures = AllocateMemory( texturesSize * SizeOf(mesh::texture) )
    Protected.Mesh::Texture *cTextures = *textures ; current write position
    
    ; load the textures and fill the textures-array
    *cTextures = _loadMaterialTextures(*model, *material, ai::#TextureType_DIFFUSE, mesh::#Texture_Diffuse, *cTextures)
    *cTextures = _loadMaterialTextures(*model, *material, ai::#TextureType_SPECULAR, mesh::#Texture_Specular, *cTextures)
    *cTextures = _loadMaterialTextures(*model, *material, ai::#TextureType_NORMALS, mesh::#Texture_Normal, *cTextures)
    *cTextures = _loadMaterialTextures(*model, *material, ai::#TextureType_HEIGHT, mesh::#Texture_Height, *cTextures)
    
    ; create a new mesh
    Protected *ret= mesh::new ( *vertices, verticesSize, *indices, indicesSize, *textures, texturesSize)
    
    ; clean up
    ; note the mesh is now responsibly for the textures
    FreeMemory(*vertices)
    FreeMemory(*indices)
    FreeMemory(*textures)
    
    ; return the mesh
    ProcedureReturn *ret   
    
  EndProcedure
  
  
  Procedure.i _loadMaterialTextures(*model.sModel, *mat.ai::Material, aiType.l, texType.l, *cTextures.mesh::Texture)
    Protected.l i 
    Protected.l count = ai::GetMaterialTextureCount(*mat, aiType)
   
    For i=0 To count -1
      Protected.ai::aiString astr
      ; get the name of the texture
      ai::GetMaterialTexture(*mat, aiType, i, astr)
      Protected.s str
      str = PeekS(@ astr\Data, astr\length,#PB_UTF8 | #PB_ByteLength)
      
      ; load and stores it
      *cTextures\id = texture::Load( *model\directory + str )
      *cTextures\type = texType
      *cTextures + SizeOf(mesh::Texture)
    Next
    
    ; return the current write position
    ProcedureReturn *cTextures
  EndProcedure
  


  
EndModule


; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 162
; FirstLine = 134
; Folding = --
; EnableXP