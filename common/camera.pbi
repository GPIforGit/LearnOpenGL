
; An abstract camera class that processes input and calculates the corresponding Euler Angles, Vectors and Matrices for use in OpenGL


; changes 
;         - add camera::delete(*camera)
;         - add #up and #down

DeclareModule camera
  EnableExplicit
  ; Defines several possible options for camera movement. Used as abstraction to stay away from window-system specific input methods
  Enumeration
    #FORWARD
    #BACKWARD
    #LEFT
    #RIGHT
    #UP
    #DOWN
  EndEnumeration
  
  ; creates a new camera
  Declare.i new( *position.math::vec3=#Null, *up.math::Vec3=#Null, yaw.f = -90.0, pitch.f = 0.0 )
  Declare.i new_float( posX.f=0, posY.f=0, posZ.f=0, upX.f=0, upY.f=1, upZ=0, yaw.f = -90.0, pitch.f = 0.0 )
  
  ; free the camera
  Declare delete( *camera)
  
  ; returns the view matrix calculated using Euler Angles and the LookAt Matrix
  Declare.i GetViewMatrix(*camera)
  
  ; processes input received from any keyboard-like input system. Accepts input parameter in the form of camera defined ENUM (to abstract it from windowing systems)
  Declare ProcessKeyboard(*camera, direction.l, deltaTime.f)
  
  ; processes input received from a mouse input system. Expects the offset value in both the x and y direction.
  Declare ProcessMouseMovement(*camera, xoffset.f, yoffset.f, constrainPitch.l = #True)
  
  ; processes input received from a mouse scroll-wheel event. Only requires input on the vertical wheel-axis
  Declare ProcessMouseScroll(*camera,yoffset.f)
  
  ; return zoom-factor
  Declare.f GetZoom(*camera)
  
  ; return camera-position
  Declare.i GetPosition(*camera)
  
  ; return front-vector (directon)
  Declare.i GetFront(*camera)
  Declare.i GetRight(*camera)
  Declare.i GetUp(*camera)
  
  ; Return the Angles
  Declare GetAngle(*camera, *pYaw.float, *pPitch.float)
  
  ; Set Angels
  Declare SetAngle(*camera, Yaw.f, Pitch.f)
  
EndDeclareModule

Module camera
  
  ; calculates the front vector from the Camera's (updated) Euler Angles
  Declare _updateCameraVectors(*camera)
    
  Structure sCamera
    Position.math::vec3
    Front.math::vec3
    Up.math::vec3
    Right.math::vec3
    WorldUp.math::vec3
    ; euler Angles
    Yaw.f
    Pitch.f
    ; camera options
    MovementSpeed.f
    MouseSensitivity.f
    Zoom.f
    ; result
    view.math::mat4x4
  EndStructure
  
  Procedure.i new( *position.math::vec3=#Null, *up.math::Vec3=#Null, yaw.f = -90.0, pitch.f = 0.0 )
    Protected *ret.sCamera = AllocateStructure(sCamera)
    
    math::vec3_set_float(*ret\Front, 0,0,-1)
    *ret\MovementSpeed = 2.5
    *ret\MouseSensitivity = 0.1
    *ret\Zoom = 45.0
    
    If *position
      math::vec3_set(*ret\Position, *position)
    Else
      math::vec3_set_float(*ret\Position, 0,0,0)
    EndIf
    
    If *up
      math::vec3_set(*ret\WorldUp, *up)
    Else
      math::vec3_set_float(*ret\WorldUp, 0,1,0)
    EndIf
    
    *ret\Yaw = yaw
    *ret\Pitch = pitch
    
    _updateCameraVectors(*ret)
    ProcedureReturn *ret
  EndProcedure
  
  Procedure.i new_float( posX.f=0, posY.f=0, posZ.f=0, upX.f=0, upY.f=1, upZ=0, yaw.f = -90.0, pitch.f = 0.0 )
    Protected *ret.sCamera = AllocateStructure(sCamera)
    
    math::vec3_set_float(*ret\Front, 0,0,-1)
    *ret\MovementSpeed = 2.5
    *ret\MouseSensitivity = 0.1
    *ret\Zoom = 45.0
    
    math::vec3_set_float(*ret\Position, posX,posY,posZ)
    math::vec3_set_float(*ret\WorldUp, upX,upY,upZ)
        
    *ret\Yaw = yaw
    *ret\Pitch = pitch
    
    _updateCameraVectors(*ret)
    ProcedureReturn *ret
  EndProcedure
  
  Procedure delete( *camera.sCamera)
    FreeStructure( *camera)
  EndProcedure
  
  Procedure.i GetViewMatrix(*camera.sCamera)
    Protected.math::vec3 tmp
    ProcedureReturn math::lookAt(*camera\view,
                                 *camera\Position,
                                 math::vec3_add(tmp, *camera\Position, *camera\Front),
                                 *camera\up)
  EndProcedure
  
  Procedure ProcessKeyboard(*camera.sCamera, direction.l, deltaTime.f)
    Protected.f velocity = *camera\MovementSpeed * deltaTime
    Protected.math::vec3 tmp
    Select direction
      Case #FORWARD
        math::vec3_add( *camera\Position, *camera\Position, math::vec3_mul_scalar(tmp, *camera\Front, velocity) )
      Case #BACKWARD  
        math::vec3_sub( *camera\Position, *camera\Position, math::vec3_mul_scalar(tmp, *camera\Front, velocity) )
      Case #LEFT
        math::vec3_sub( *camera\Position, *camera\Position, math::vec3_mul_scalar(tmp, *camera\Right, velocity) )
      Case #RIGHT
        math::vec3_add( *camera\Position, *camera\Position, math::vec3_mul_scalar(tmp, *camera\Right, velocity) )
      Case #UP
        math::vec3_add( *camera\Position, *camera\Position, math::vec3_mul_scalar(tmp, *camera\WorldUp, velocity) )
      Case #DOWN
        math::vec3_sub( *camera\Position, *camera\Position, math::vec3_mul_scalar(tmp, *camera\WorldUp, velocity) )
    EndSelect
    
    ;Debug math::vec3_string( *camera\Position)
    
  EndProcedure 
  
  Procedure ProcessMouseMovement(*camera.Scamera, xoffset.f, yoffset.f, constrainPitch.l = #True)
    xoffset * *camera\MouseSensitivity
    yoffset * *camera\MouseSensitivity
    
    *camera\Yaw   + xoffset;
    *camera\Pitch + yoffset;
    
    ; make sure that when pitch is out of bounds, screen doesn't get flipped
    If constrainPitch
      If *camera\Pitch > 89.0
        *camera\Pitch = 89.0
      ElseIf *camera\Pitch < -89.0
        *camera\Pitch = -89.0
      EndIf
    EndIf
    
    ;Debug " "+ *camera\Yaw + " " + *camera\Pitch
    
    ; update Front, Right and Up Vectors using the updated Euler angles
    _updateCameraVectors(*camera)
  EndProcedure
  
  Procedure ProcessMouseScroll(*camera.Scamera,yoffset.f)    
    *camera\Zoom - yoffset
    If *camera\Zoom < 1.0
      *camera\Zoom = 1.0
    ElseIf *camera\Zoom > 45.0
      *camera\Zoom = 45.0
    EndIf
  EndProcedure
  
  Procedure _updateCameraVectors(*camera.Scamera)
    ; calculate the new Front vector
    Protected.math::vec3 front
    front\x = Cos(Radian(*camera\Yaw)) * Cos(Radian(*camera\Pitch))
    front\y = Sin(Radian(*camera\Pitch))
    front\z = Sin(Radian(*camera\Yaw)) * Cos(Radian(*camera\Pitch))
    math::vec3_normalize(*camera\Front, front)
    
    ; also re-calculate the Right And Up vector
    Protected.math::vec3 tmp
    math::vec3_normalize(*camera\Right, math::Vec3_Cross(tmp, *camera\Front, *camera\WorldUp) );normalize the vectors, because their length gets closer to 0 the more you look up or down which results in slower movement.
    math::vec3_normalize(*camera\Up   , math::Vec3_Cross(tmp, *camera\Right, *camera\Front) )
    
  EndProcedure
      
  Procedure.f GetZoom(*camera.sCamera)
    ProcedureReturn *camera\Zoom
  EndProcedure
  
  Procedure.i GetPosition(*camera.sCamera)
    ProcedureReturn *camera\Position
  EndProcedure
  
  Procedure.i GetFront(*camera.sCamera)
    ProcedureReturn *camera\Front
  EndProcedure
  Procedure.i GetRight(*camera.sCamera)
    ProcedureReturn *camera\Right
  EndProcedure
  Procedure.i GetUp(*camera.sCamera)
    ProcedureReturn *camera\Up
  EndProcedure
  
  Procedure GetAngle(*camera.sCamera, *pYaw.float, *pPitch.float)
    *pYaw\f = *camera\Yaw
    *pPitch\f = *camera\Pitch
  EndProcedure
  Procedure SetAngle(*camera.sCamera, Yaw.f, Pitch.f)
    *camera\Yaw = yaw
    *camera\Pitch = pitch
    _updateCameraVectors(*camera)
  EndProcedure
EndModule

