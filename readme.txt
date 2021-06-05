I translated the examples from

https://learnopengl.com/

for PureBasic

I use SDL, Assimp and my Math-includefiles, you need them to compile the examples

https://github.com/GPIforGit/SDL_For_PB/releases
https://github.com/GPIforGit/math/releases
https://github.com/GPIforGit/assimp-for-PB/releases

all codes expect, that you use the installscript and the include-files are in the pb-compiler-directory

All codes should work in Windows, MacOs and Linux.

I had to rewrite many codes to work with PB. I tried to remain the structure of the original, but it was not always possible. But the comments in the source should guide you.

I also add many cleanup, since the original code doesn't do this everywhere (for example release a scene when loading a model with assimp).