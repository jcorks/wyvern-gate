"use strict";


/// main text renderer for webGL

var TextRenderer;

var initializeTextRenderer = function() {
    const TEXT_RENDERER_WIDTH = 80;
    const TEXT_RENDERER_HEIGHT = 24;

    const ATLAS_CHARS_PER_ROW = 24;
    const ATLAS_CHARS_PER_COLUMN = 20;
    const ATLAS_CHARS_WIDTH_TEXELS = 13;
    const ATLAS_CHARS_HEIGHT_TEXELS = 25;
    const ATLAS_FONT = "26px gamefont";
    
    
    const BACKGROUND_COLOR = "#323232";
    const FOREGROUND_COLOR = "#e4F5F5"






    function hexRgb(hex) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return {
            r: parseInt(result[1]) / 255.0,
            g: parseInt(result[2]) / 255.0,
            b: parseInt(result[3]) / 255.0
        }
    }



    // creates the basic text atlas
    const newTextAtlas = function() {

        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        

        const height = ATLAS_CHARS_HEIGHT_TEXELS * ATLAS_CHARS_PER_COLUMN;
        const width = ATLAS_CHARS_PER_ROW * ATLAS_CHARS_WIDTH_TEXELS;
        
        var pointerX = 0;
        var pointerY = 0;        
        var legend = {};

        const blankCanvas = document.createElement("canvas").getContext("2d");
        blankCanvas.fillStyle = BACKGROUND_COLOR;




        const characterCanvas = document.createElement("canvas").getContext("2d");
        characterCanvas.canvas.width = ATLAS_CHARS_WIDTH_TEXELS;
        characterCanvas.canvas.height = ATLAS_CHARS_HEIGHT_TEXELS;
        characterCanvas.font = ATLAS_FONT;
        characterCanvas.textAlign = "center";
        characterCanvas.textBaseline = "middle";
        characterCanvas.fillStyle = FOREGROUND_COLOR;
        //characterCanvas.imageSmoothingEnabled = false;
        //characterCanvas.fontSmooth = "never";
        
        
        const renderCharacter = function(ch) {
            characterCanvas.fillStyle = BACKGROUND_COLOR;
            characterCanvas.clearRect(0, 0, ATLAS_CHARS_WIDTH_TEXELS, ATLAS_CHARS_HEIGHT_TEXELS);
            characterCanvas.fillStyle = FOREGROUND_COLOR;
            characterCanvas.fillText(ch, Math.floor(ATLAS_CHARS_WIDTH_TEXELS/ 2), Math.floor(ATLAS_CHARS_HEIGHT_TEXELS / 2));
        }


        
        const setupAtlas = function() {
            
            blankCanvas.canvas.width = width;
            blankCanvas.canvas.height = height;
            blankCanvas.clearRect(0, 0, width, height);
            
            gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texImage2D(
                gl.TEXTURE_2D,
                0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, blankCanvas.canvas
            );            
        }

        setupAtlas();
        
        return {
            getLegend : function() {return legend;},
            
            dumpFont : function() {
                pointerX = 0;
                pointerY = 0;
                legend = {};
            },
            
            loadCharacter : function(ch) {
                renderCharacter(ch);
                
                if (pointerX >= width) {
                    pointerX = 0;
                    pointerY += ATLAS_CHARS_HEIGHT_TEXELS;
                }        
                
                gl.bindTexture(gl.TEXTURE_2D, texture);
                gl.texSubImage2D(
                    gl.TEXTURE_2D,
                    0,
                    pointerX,
                    pointerY,
                    gl.RGBA, gl.UNSIGNED_BYTE,
                    characterCanvas.canvas
                );
                
                legend[ch] = {
                    x  : pointerX,
                    y  : pointerY,
                    u0 : pointerX / width,
                    u1 : (pointerX + ATLAS_CHARS_WIDTH_TEXELS-1) / width,
                    v0 : pointerY / height,
                    v1 : (pointerY + ATLAS_CHARS_HEIGHT_TEXELS-1) / height
                }
                
                pointerX += ATLAS_CHARS_WIDTH_TEXELS;
            },
            
            recalculateUVs : function() {
                legend.forEach(function(info, ch) {
                    info.u0 = info.x / width,
                    info.u1 = (info.x + ATLAS_CHARS_WIDTH_TEXELS-1) / width,
                    info.v0 = info.y / height,
                    info.u1 = (info.y + ATLAS_CHARS_HEIGHT_TEXELS-1) / height
                });
            },
            
            getTexture : function() {return texture;},
            width : function() {return width;},
            height : function() {return height;},
            charWidth : function() {return ATLAS_CHARS_WIDTH_TEXELS;},
            charHeight : function() {return ATLAS_CHARS_HEIGHT_TEXELS;}
        }
    }


    // creates a complete shader program, throwing an error on failure.
    const newProgram = function(vertexSource, fragmentSource) {
        var gl = canvas.getContext("webgl");
        const newShader = function(source, isVertex) {
            const shader = gl.createShader(isVertex ? gl.VERTEX_SHADER : gl.FRAGMENT_SHADER);
            gl.shaderSource(shader, source);
            gl.compileShader(shader);
            
            if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
                // Something went wrong during compilation; get the error
                const lastError = gl.getShaderInfoLog(shader);
                throw new Error(
                    'Shader failed to compile:' + lastError
                );
                gl.deleteShader(shader);
            }
            return shader;
        }


        const program = gl.createProgram();
        const vertShader = newShader(vertexSource, true);
        const fragShader = newShader(fragmentSource, false);

        gl.attachShader(program, vertShader);
        gl.attachShader(program, fragShader);
        gl.linkProgram(program)
        
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            const lastError = gl.getProgramInfoLog(program);
            throw new Error('Program failed to link:' + lastError);        
        }
        
        return program;
    }


    // creates a new mesh for a line of text.
    const newLineMesh = function(baseY, atlas) {
        const LINE_MAX_VERTICES = TEXT_RENDERER_WIDTH * 6;

        var gl = canvas.getContext("webgl");

        const posBuffer   = new Float32Array(LINE_MAX_VERTICES * 2);
        const texBuffer   = new Float32Array(LINE_MAX_VERTICES * 2);
        var currentText   = ""; // used to skip recalculating line on repeats.

        const posGLBuffer = gl.createBuffer();
        const texGLBuffer = gl.createBuffer();

        var numVertices = 0;
        

        const reformBuffer = function() {            
            
            const text = currentText;
            const len = text.length;
            numVertices = 0;
            var offset = 0;
            var x = 0;
            
            const cWidth = atlas.charWidth();
            const cHeight = atlas.charHeight();
            
            for(var i = 0; i < len; ++i) {
                var letter = text[i];
                if (letter == ' ') {
                    x += cWidth;
                    continue;
                }

                var glyphInfo = atlas.getLegend()[letter];
                
                if (!glyphInfo) {
                    atlas.loadCharacter(letter);
                    glyphInfo = atlas.getLegend()[letter];
                }
                
                var x2 = x + cWidth;
                var u1 = glyphInfo.u0;
                var v1 = glyphInfo.v0;
                var u2 = glyphInfo.u1;
                var v2 = glyphInfo.v1;

                // 6 vertices per letter
                posBuffer[offset + 0] = x;
                posBuffer[offset + 1] = baseY;
                texBuffer[offset + 0] = u1;
                texBuffer[offset + 1] = v1;

                posBuffer[offset + 2] = x2;
                posBuffer[offset + 3] = baseY;
                texBuffer[offset + 2] = u2;
                texBuffer[offset + 3] = v1;

                posBuffer[offset + 4] = x;
                posBuffer[offset + 5] = baseY + cHeight;
                texBuffer[offset + 4] = u1;
                texBuffer[offset + 5] = v2;

                posBuffer[offset + 6] = x;
                posBuffer[offset + 7] = baseY + cHeight;
                texBuffer[offset + 6] = u1;
                texBuffer[offset + 7] = v2;

                posBuffer[offset + 8] = x2;
                posBuffer[offset + 9] = baseY;
                texBuffer[offset + 8] = u2;
                texBuffer[offset + 9] = v1;

                posBuffer[offset + 10] = x2;
                posBuffer[offset + 11] = baseY + cHeight;
                texBuffer[offset + 10] = u2;
                texBuffer[offset + 11] = v2;

                x += cWidth;
                offset += 12;
                numVertices += 6;
            }
            
            gl.bindBuffer(gl.ARRAY_BUFFER, posGLBuffer);
            gl.bufferData(gl.ARRAY_BUFFER, posBuffer, gl.DYNAMIC_DRAW);
            gl.bindBuffer(gl.ARRAY_BUFFER, texGLBuffer);
            gl.bufferData(gl.ARRAY_BUFFER, texBuffer, gl.DYNAMIC_DRAW);    
        }


        return {
            // sets the text, reforming the buffer if needed
            setText : function(text) {
                if (text == currentText) return;
                currentText = text;
                return reformBuffer();
            },
            
            // completely resets the buffer
            reformBuffer : reformBuffer,
            
            // draws the line using the current program.
            draw : function(
                posAttribIndex,
                texAttribIndex
            ) {


                gl.bindBuffer(gl.ARRAY_BUFFER, posGLBuffer);
                gl.vertexAttribPointer(posAttribIndex, 2, gl.FLOAT, false, 0, 0);

                gl.bindBuffer(gl.ARRAY_BUFFER, texGLBuffer);
                gl.vertexAttribPointer(texAttribIndex, 2, gl.FLOAT, false, 0, 0);

                gl.drawArrays(gl.TRIANGLES, 0, numVertices);
            },
            
            getNumVertices : function() {
                return numVertices;
            }
        }
    }



    const framebufferCreate = function(width, height) {
        const fbo = gl.createFramebuffer();
        const fbt = gl.createTexture();

        gl.bindTexture(gl.TEXTURE_2D, fbt);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);


        const blankCanvas = document.createElement("canvas").getContext("2d");
        blankCanvas.fillStyle = "#ff00ff";


        // we actually... dont need a depth buffer since we're just 
        // drawing 2D text, so no need to attach a renderbuffer....

        const resizeTexture = function() {
            gl.bindTexture(gl.TEXTURE_2D, fbt);
            blankCanvas.canvas.width = width;
            blankCanvas.canvas.height = height;
            blankCanvas.fillRect(0, 0, width, height);
            
            gl.texImage2D(
                gl.TEXTURE_2D,
                0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, blankCanvas.canvas
            );
            
            gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
            gl.framebufferTexture2D(
                gl.FRAMEBUFFER,
                gl.COLOR_ATTACHMENT0,
                gl.TEXTURE_2D,
                fbt,
                0
            );
            
        }
        
        resizeTexture();

        return {
            resize : function(w, h) {
                width = h;
                height = h;
                resizeTexture();
            },
            
            fbo : fbo,
            texture : fbt,
            
            width : function() {return width;},
            height : function() {return height;}
        }
    }


    const createCRT = function(framebuffer) {

        const program = newProgram(
            // vertex shader
            "attribute vec4 a_position;\n"+
            "attribute vec2 a_texcoord;\n"+
            "varying vec2 v_texcoord;\n"+
            "void main() {\n"+
            "  gl_Position = a_position;\n"+
            "  v_texcoord = a_texcoord;\n"+
            "}\n",
            
            // fragment shader        
            "precision mediump float;\n"+
            "varying vec2 v_texcoord;\n"+
            "uniform sampler2D u_texture;\n"+
            "uniform vec2 u_resolution;\n"+ 
            "void main() {\n"+
            "    vec2 fragcoord = v_texcoord*u_resolution.xy;\n"+
            "    float apply = abs(sin(fragcoord.y) * 0.5 * 0.8);\n"+
            "    gl_FragColor = vec4(mix(texture2D(u_texture, v_texcoord).rgb, vec3(0.1), apply), 1.0);\n"+
            "}\n"
        );
        
        
        const u_textureLocation    = gl.getUniformLocation(program, 'u_texture');
        const u_resolutionLocation = gl.getUniformLocation(program, 'u_resolution');
        
        
        const posAttribIndex = gl.getAttribLocation(program, 'a_position');
        const texAttribIndex = gl.getAttribLocation(program, 'a_texcoord');
        
        
        const posBuffer   = new Float32Array(12);
        const texBuffer   = new Float32Array(12);
        
        posBuffer[0] = -1.0; texBuffer[0] = 0;
        posBuffer[1] = -1.0; texBuffer[1] = 0;

        posBuffer[2] =  1.0; texBuffer[2] = 1;
        posBuffer[3] = -1.0; texBuffer[3] = 0;

        posBuffer[4] =  1.0; texBuffer[4] = 1;
        posBuffer[5] =  1.0; texBuffer[5] = 1;

        posBuffer[6] =  1.0; texBuffer[6] = 1;
        posBuffer[7] =  1.0; texBuffer[7] = 1;

        posBuffer[8] = -1.0; texBuffer[8] = 0;
        posBuffer[9] =  1.0; texBuffer[9] = 1;

        posBuffer[10] = -1.0; texBuffer[10] = 0;
        posBuffer[11] = -1.0; texBuffer[11] = 0;


        const posGLBuffer = gl.createBuffer();
        const texGLBuffer = gl.createBuffer();

        gl.bindBuffer(gl.ARRAY_BUFFER, posGLBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, posBuffer, gl.STATIC_DRAW);
        gl.bindBuffer(gl.ARRAY_BUFFER, texGLBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, texBuffer, gl.STATIC_DRAW);    


        return {
            draw : function() {
                gl.useProgram(program);
                

                gl.uniform1i(u_textureLocation, 0);
                gl.activeTexture(gl.TEXTURE0 + 0);
                gl.bindTexture(gl.TEXTURE_2D, framebuffer.texture);
                gl.uniform2fv(u_resolutionLocation, [framebuffer.width(), framebuffer.height()]);
                            
                gl.enableVertexAttribArray(posAttribIndex);
                gl.enableVertexAttribArray(texAttribIndex);


                gl.bindBuffer(gl.ARRAY_BUFFER, posGLBuffer);
                gl.vertexAttribPointer(posAttribIndex, 2, gl.FLOAT, false, 0, 0);

                gl.bindBuffer(gl.ARRAY_BUFFER, texGLBuffer);
                gl.vertexAttribPointer(texAttribIndex, 2, gl.FLOAT, false, 0, 0);


                gl.drawArrays(gl.TRIANGLES, 0, 6);

                gl.disableVertexAttribArray(posAttribIndex);
                gl.disableVertexAttribArray(texAttribIndex);

            }
        }
    }




   
    const canvas = document.querySelector("#canvas");
    const gl = canvas.getContext("webgl");

    const workingFramebuffer = framebufferCreate(
        TEXT_RENDERER_WIDTH * ATLAS_CHARS_WIDTH_TEXELS,
        TEXT_RENDERER_HEIGHT * ATLAS_CHARS_HEIGHT_TEXELS
    );

    const CRT = createCRT(workingFramebuffer);

    // create the base program.
    const textProgram = newProgram(
        // vertex shader
        "attribute vec4 a_position;\n"+
        "attribute vec2 a_texcoord;\n"+
        "uniform mat4 u_matrix;\n"+
        "varying vec2 v_texcoord;\n"+
        "void main() {\n"+
        "  gl_Position = u_matrix * a_position;\n"+
        "  v_texcoord = a_texcoord;\n"+
        "}\n",
        
        // fragment shader
        "precision mediump float;\n"+
        "varying vec2 v_texcoord;\n"+
        "uniform sampler2D u_texture;\n"+
        "void main() {\n"+
        "   gl_FragColor = texture2D(u_texture, v_texcoord);\n"+
        "}\n"
    )



    const atlas = newTextAtlas();
    const glyphTex = atlas.getTexture();


    var textUniforms = {
        u_matrix: m4.identity(),
        u_texture: glyphTex,
        u_color: [0, 0, 0, 1],  // black
    };

    const bgRGB = hexRgb(BACKGROUND_COLOR);
    gl.clearColor(bgRGB.r, bgRGB.g, bgRGB.b, 1);


    /// assign locations and data.
    
    const u_matrixLocation = gl.getUniformLocation(textProgram, 'u_matrix');
    const u_textureLocation = gl.getUniformLocation(textProgram, 'u_texture');




    const lines = [];
    for(var i = 0; i < TEXT_RENDERER_HEIGHT; ++i) {
        lines[i] = newLineMesh(i * atlas.charHeight(), atlas);
    }


    var pendingDraw = false;

    const posAttribIndex = gl.getAttribLocation(textProgram, 'a_position');
    const texAttribIndex = gl.getAttribLocation(textProgram, 'a_texcoord');

    const canvasElement = document.getElementById("canvas");
    const drawFrame = function() {
        canvasElement.width = canvasElement.clientWidth;
        canvasElement.height = canvasElement.clientHeight;
    
        gl.viewport(0, 0, workingFramebuffer.width(), workingFramebuffer.height());
    
    
        gl.bindFramebuffer(gl.FRAMEBUFFER, workingFramebuffer.fbo);
        gl.disable(gl.BLEND);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
        gl.depthMask(false);
        gl.useProgram(textProgram);
        
        

        ///// only needed if size changed
            var projectionMatrix = m4.orthographic(
                0, workingFramebuffer.width(),
                workingFramebuffer.height(), 0,
                -1,
                1
            );
            gl.uniformMatrix4fv(u_matrixLocation, false, projectionMatrix);
            gl.uniform1i(u_textureLocation, 0);
            gl.activeTexture(gl.TEXTURE0 + 0);
            gl.bindTexture(gl.TEXTURE_2D, glyphTex);
        ////
        

        gl.enableVertexAttribArray(posAttribIndex);
        gl.enableVertexAttribArray(texAttribIndex);

        
        for(var i = 0; i < lines.length; ++i) {
            lines[i].draw(
                posAttribIndex,
                texAttribIndex
            );
        }    

        gl.disableVertexAttribArray(posAttribIndex);
        gl.disableVertexAttribArray(texAttribIndex);
                
        gl.flush();
        
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
        
        CRT.draw();

        pendingDraw = false;
    }


    TextRenderer =  {
        setLine : function(line, text) {
            lines[line].setText(text)
        },
        
        dumpFont : function() {
            atlas.dumpFont();
            for(var i = 0; i < lines.length; ++i) {
                lines[i].reformBuffer();
            }
        },
        
        requestDraw : function() {
            if (pendingDraw) return;
            pendingDraw = true;
            /*
            // UVs changed since last draw. Need to 
            // reform the UVs and the meshes.
            if (needsRecalculate) {
                atlas.recalculateUVs();
                for(var i = 0; i < lines.length; ++i) {
                    lines[i].reformBuffer();
                }
                needsRecalculate = false;
            }
            */
            requestAnimationFrame(drawFrame);
        }
    }
    
    TextRenderer.setLine(0, 'Loading...');
    TextRenderer.requestDraw();

    document.fonts.ready.then(function() {
        TextRenderer.dumpFont();
        TextRenderer.requestDraw();
    });    
    
};





