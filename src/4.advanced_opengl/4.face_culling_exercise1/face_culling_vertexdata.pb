
;     Remember: to specify vertices in a counter-clockwise winding order you need to visualize the triangle
;     As if you're in front of the triangle and from that point of view, is where you set their order.
;     
;     To define the order of a triangle on the right side of the cube for example, you'd imagine yourself looking
;     straight at the right side of the cube, and then visualize the triangle and make sure their order is specified
;     in a counter-clockwise order. This takes some practice, but try visualizing this yourself and see that this
;     is correct.


DataSection
  cubeVertices:
  ; Back face
  Data.f -0.5, -0.5, -0.5,  0.0, 0.0, ; Bottom-left
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right
         0.5, -0.5, -0.5,  1.0, 0.0,  ; bottom-right         
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right
         -0.5, -0.5, -0.5,  0.0, 0.0, ; bottom-left
         -0.5,  0.5, -0.5,  0.0, 1.0  ; top-left
                                      ; Front face
  Data.f -0.5, -0.5,  0.5,  0.0, 0.0, ; bottom-left
         0.5, -0.5,  0.5,  1.0, 0.0,  ; bottom-right
         0.5,  0.5,  0.5,  1.0, 1.0,  ; top-right
         0.5,  0.5,  0.5,  1.0, 1.0,  ; top-right
         -0.5,  0.5,  0.5,  0.0, 1.0, ; top-left
         -0.5, -0.5,  0.5,  0.0, 0.0  ; bottom-left
                                      ; Left face
  Data.f -0.5,  0.5,  0.5,  1.0, 0.0, ; top-right
         -0.5,  0.5, -0.5,  1.0, 1.0, ; top-left
         -0.5, -0.5, -0.5,  0.0, 1.0, ; bottom-left
         -0.5, -0.5, -0.5,  0.0, 1.0, ; bottom-left
         -0.5, -0.5,  0.5,  0.0, 0.0, ; bottom-right
         -0.5,  0.5,  0.5,  1.0, 0.0  ; top-right
                                      ; Right face
  Data.f 0.5,  0.5,  0.5,  1.0, 0.0,  ; top-left
         0.5, -0.5, -0.5,  0.0, 1.0,  ; bottom-right
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right         
         0.5, -0.5, -0.5,  0.0, 1.0,  ; bottom-right
         0.5,  0.5,  0.5,  1.0, 0.0,  ; top-left
         0.5, -0.5,  0.5,  0.0, 0.0   ; bottom-left     
                                      ; Bottom face
  Data.f -0.5, -0.5, -0.5,  0.0, 1.0, ; top-right
         0.5, -0.5, -0.5,  1.0, 1.0,  ; top-left
         0.5, -0.5,  0.5,  1.0, 0.0,  ; bottom-left
         0.5, -0.5,  0.5,  1.0, 0.0,  ; bottom-left
         -0.5, -0.5,  0.5,  0.0, 0.0, ; bottom-right
         -0.5, -0.5, -0.5,  0.0, 1.0  ; top-right
                                      ; Top face
  Data.f -0.5,  0.5, -0.5,  0.0, 1.0, ; top-left
         0.5,  0.5,  0.5,  1.0, 0.0,  ; bottom-right
         0.5,  0.5, -0.5,  1.0, 1.0,  ; top-right     
         0.5,  0.5,  0.5,  1.0, 0.0,  ; bottom-right
         -0.5,  0.5, -0.5,  0.0, 1.0, ; top-left
         -0.5,  0.5,  0.5,  0.0, 0.0  ; bottom-left        
  cubeVerticesEnd:
EndDataSection
