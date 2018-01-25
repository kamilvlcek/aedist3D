classdef Scene
    % SCENE is complex object which contains trial information
    %   and scene information. In future it would be easy to
    %   implement this as full experiment with easily generated 
    %   3D objects in it.
    %
    % Important: 
    %   Psychtoolbox is used for OpenGL. Tested with
    %   version 3.0.14 Flavor macOS, MATLAB 2016b. You can
    %   easily check your version with PsychtoolboxVersion or
    %   simply download toolbox at http://psychtoolbox.org
    %
    % Created by:
    %   Michael Tesar michtesar@gmail.com
    %   http://www.neurosciencemike.wordpress.com
    %   2017 Ceske Budejovice
    %
    % Example:
    %   OneCube = Scene(2, 45, [0, 0, 0], {'k'}, {'Demo'});
    %   OneCube.drawcubes();
    %
    % See also:
    %   glutSolidCube
    %   PsychtoolboxVersion
    %   glutSolidSphere
    %   glRotatef
    %   glTranslatef
    %   Screen
    %   KbWait
    %
    properties
        cubeSize        % Cube/s size cubeSize = 1, cubeSize = [2, 3]
        cubeRotation    % Cube rotation of X axe matrix (25, [25, 45, 40]
        cubeCoordinate  % Cube coordinates X, Y and Z ([1, 2, 3] or [1, 2, 3; 4, 5, 6]
        cubeColor       % Cube color in Matlab notation 'k', 'b', 'r'...
        type            % Trial type for future experimental trials
    end
    
    methods
        
        function obj = Scene(cubeSize, cubeRoration,...
                cubeCoordinate, cubeColor, type)
        % Object constructor require cube parameters and
        %   trial related parameters such as:
        %
        % Input:
        %   cubeSize - cube size in meters
        %   cubeRotation - degrees of X age rotation
        %   cubeCoordinate - X, Y and Z coordinates, can
        %       be entered as array, e.g. [1, 2, 3; 4, 5, 6]
        %       for two cubes for example
        %   cubeColor - color in Matlab notation 'k', 'r' etc.
        %   type - trial type of experiment
        %
        % Output:
        %   Object instance
        %
        % Important:
        %   If no inputs delivered only one standard cube is
        %   used with size of 2, rotation 45 degrees in the center
        %   with white color.
        %
            if nargin < 1
                obj.cubeSize = 2;
                obj.cubeRotation = 45;
                obj.cubeCoordinate = [0, 0, 0];
                obj.cubeColor = 'None';
                obj.type = 'Demo';
            else
                obj.cubeSize = cubeSize;
                obj.cubeRotation = cubeRoration;
                obj.cubeCoordinate = cubeCoordinate;
                obj.cubeColor = cubeColor;
                obj.type = type;
            end
        end
             
        function drawcubes(obj)
        % Drawcubes is method of the instance.
        %
        % This method draw specified number of cubes based on
        % level of arrays with specified properties such as
        % color etc.
        %
        % Input:
        %   obj - whole object which has to contain all properties
        %
        % Output:
        %   None
        %
            try
                isCorrectSize = length(obj.cubeCoordinate) == 3;
            catch
                disp('Wrong size. Number of objects has to exact.')
            end
            
            % Only run if object is correct
            if isCorrectSize
                
                try
                    % Run OpenGL
                    AssertOpenGL;
                catch ME
                    disp(ME)
                    error('Cant run OpenGL. Have you installed Psychtoolbox?')
                end

                try
                    % Psychtoolbox screen setup
                    screenId = max(Screen('Screens'));
                    Screen('Preference', 'SkipSyncTests', 1);
                    InitializeMatlabOpenGL(1);
                    [window, winRect] = Screen('OpenWindow', screenId);
                    Screen('BeginOpenGL', window);
                    ratio = winRect(4) / winRect(3);
                catch ME
                    disp(ME)
                    disp('Cannot initialize screen from some reason.')
                end
                
                try
                    % Set up OpenGL
                    glEnable(GL_LIGHTING);
                    glEnable(GL_LIGHT0);
                    glLightModelfv(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
                    glEnable(GL_DEPTH_TEST); 
                    glMatrixMode(GL.PROJECTION);
                    glLoadIdentity;
                    gluPerspective(25, 1/ratio, 0.1, 100);
                    glMatrixMode(GL_MODELVIEW);
                    glLoadIdentity;
                    gluLookAt(0, 0, 10, 0, 0, 0, 0, 1, 0);
                    glClearColor(0, 0, 0, 0);
                    glClear;
                    glPushMatrix;
                catch ME
                    disp(ME)
                    disp('Cannot construct OpenGL scene.')
                end
                
                % Loop over all cubes in array
                nCube = numel(obj.cubeCoordinate) /...
                    length(obj.cubeCoordinate);
                for cube = 1:nCube
                    thisCubeX = obj.cubeCoordinate(cube, 1);
                    thisCubeY = obj.cubeCoordinate(cube, 2);
                    thisCubeZ = obj.cubeCoordinate(cube, 3);
                    thisCubeSize = obj.cubeSize(cube);
                    thisCubeColor = obj.cubeColor{cube};
                    thisCubeRotation = obj.cubeRotation(cube);
                  
                    try
                        glRotatef(thisCubeRotation, 0, 1, 0);
                        glTranslatef(thisCubeX, thisCubeY, thisCubeZ);
                        glutSolidCube(thisCubeSize);
                    catch
                        disp('Cannot draw a solid cube.')
                    end
                end
               
                glPopMatrix;
               
                try
                    % Clear buffer and flip window
                    Screen('EndOpenGL', window);
                    Screen('Flip', window);
                    KbWait(-1);
                    sca;
                catch
                    disp('Cannot uninitialize the screen.')
                end
                
            end
            
        end
        
    end
    
end