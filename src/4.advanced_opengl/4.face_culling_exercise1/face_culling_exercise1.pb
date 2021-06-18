DataSection
  cubeVertices:
  ; back face
  Data.f -0.5, -0.5, -0.5,  0.0, 0.0, ; bottom-left
         0.5, -0.5, -0.5,  1.0, 0.0,  ; bottom-right    
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right              
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right
         -0.5,  0.5, -0.5,  0.0, 1.0, ; top-left
         -0.5, -0.5, -0.5,  0.0, 0.0  ; bottom-left                
                                      ; front face
  Data.f -0.5, -0.5,  0.5,  0.0, 0.0, ; bottom-left
         0.5,  0.5,  0.5,  1.0, 1.0,  ; top-right
         0.5, -0.5,  0.5,  1.0, 0.0,  ; bottom-right        
         0.5,  0.5,  0.5,  1.0, 1.0,  ; top-right
         -0.5, -0.5,  0.5,  0.0, 0.0, ; bottom-left
         -0.5,  0.5,  0.5,  0.0, 1.0  ; top-left        
                                      ; left face
  Data.f -0.5,  0.5,  0.5,  1.0, 0.0, ; top-right
         -0.5, -0.5, -0.5,  0.0, 1.0, ; bottom-left
         -0.5,  0.5, -0.5,  1.0, 1.0, ; top-left       
         -0.5, -0.5, -0.5,  0.0, 1.0, ; bottom-left
         -0.5,  0.5,  0.5,  1.0, 0.0, ; top-right
         -0.5, -0.5,  0.5,  0.0, 0.0  ; bottom-right
                                      ; right face
  Data.f 0.5,  0.5,  0.5,  1.0, 0.0,  ; top-left
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right      
         0.5, -0.5, -0.5,  0.0, 1.0,  ; bottom-right          
         0.5, -0.5, -0.5,  0.0, 1.0,  ; bottom-right
         0.5, -0.5,  0.5,  0.0, 0.0,  ; bottom-left
         0.5,  0.5,  0.5,  1.0, 0.0   ; top-left
                                      ; bottom face          
  Data.f -0.5, -0.5, -0.5,  0.0, 1.0, ; top-right
         0.5, -0.5,  0.5,  1.0, 0.0,  ; bottom-left
         0.5, -0.5, -0.5,  1.0, 1.0,  ; top-left        
         0.5, -0.5,  0.5,  1.0, 0.0,  ; bottom-left
         -0.5, -0.5, -0.5,  0.0, 1.0, ; top-right
         -0.5, -0.5,  0.5,  0.0, 0.0  ; bottom-right
                                      ; top face
  Data.f -0.5,  0.5, -0.5,  0.0, 1.0, ; top-left
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right
         0.5,  0.5,  0.5,  1.0, 0.0,  ; bottom-right                 
         0.5,  0.5,  0.5,  1.0, 0.0,  ; bottom-right
         -0.5,  0.5,  0.5,  0.0, 0.0, ; bottom-left  
         -0.5,  0.5, -0.5,  0.0, 1.0  ; top-left            
  cubeVerticesEnd:
EndDataSection

; Also make sure to add a call to OpenGL to specify that triangles defined by a clockwise ordering 
; are now 'front-facing' triangles so the cube is rendered as normal:
; gl::FrontFace(GL::#CW)

