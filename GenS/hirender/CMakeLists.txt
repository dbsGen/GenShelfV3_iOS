cmake_minimum_required(VERSION 3.5)
project(hirender)

include_directories("." "thirdparties")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(RENDER_SRC
        Renderer.cpp
        Object.cpp
        material/Material.cpp
        mesh/Mesh.cpp
        mesh/Panel.cpp
        math/Type.cpp
        texture/Texture.cpp
        texture/Texture.h
        material/Shader.cpp
        material/Shader.h
        core/Class.cpp
        texture/ImageTexture.cpp
        texture/ColorTexture.cpp
        texture/ProxyTexture.cpp
        graphics/Factory.cpp
        graphics/opengl2/GL2MaterialIMP.cpp
        graphics/opengl2/GL2MeshIMP.cpp
        graphics/opengl2/GL2RendererIMP.cpp
        graphics/opengl2/GL2ShaderIMP.cpp
        graphics/opengl2/GL2TextureIMP.cpp
        graphics/opengl2/shaderPaser/GL2Parser.cpp
        graphics/opengl2/shaderPaser/GL2Tokenizer.cpp
        )
add_library(render STATIC ${RENDER_SRC})

set(SOURCE_FILES test/main.cpp ${RENDER_SRC})
add_executable(hirender ${SOURCE_FILES})

