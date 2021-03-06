
function proj_lengths = lightCurve(accuracy,angle,shape)

% This function gives the light curve data with a given angle and accuracy
%
% parameters:
%   accuracy:    accuracy of the measurement (How many light-rays)
%   angle:       angle between viewer's direction and light source
%   shape:       shape of the asteroid
%
% Tomi Kallava 2017

% pre-process data
data = preProc(shape);

if angle > 2*pi || angle < 0
    error('Angle between 0 and 2*pi')
end

% for convenience, make angle to be related to x-axis
angle = angle - pi/2;
if angle == 2*pi
    angle = 0;
end

if angle > 2*pi
    angle = angle - 2*pi;
end 

% avoid infinities caused by slope being 0 or Inf 
if angle == 0 | angle == pi/2 | angle == pi | angle == 3*pi/2
    angle = angle + 0.001;
end

% the slope of light rays
slope = tan(angle);

% from which quadrant light is coming towards origin
if (angle > 0 & angle < pi/2)
    quad = 1;
elseif (angle > pi/2 & angle < pi)
    quad = 2;
elseif (angle > pi & angle < 3*pi/2)
    quad = 3;
elseif (angle > 3*pi/2 & angle < 2*pi)
    quad = 4;
else
    error('Choose better angle!')
end

% x-coordinates for lines plotting
x1 = linspace(-1,1,100);

% rotation matrix
rot = [cos(2*pi/50) -sin(2*pi/50);sin(2*pi/50) cos(2*pi/50)];

% lengths of projections
proj_lengths = zeros(50,1);

%%
% Here begins the loop jungle, where we rotate the asteroid, go through all
% light rays point by point and see which rays reflect to the viewer.
%
% At each step we call the projLength-function to analyze if the area of 
% asteroid between two consecutive visible points is also visible. So we'll
% find out the projection length.
%
% Rotate the asteroid full circle in 50 steps
for kkk = 1:50
    
    % the smallest y-coordinate
    y_min = min(data(:,2));

    % first line passes through y1_0 when x=0 with given slope 
    y1_0 = min(data(:,2)-slope.*data(:,1));
    
    % last line passes through y2_0 with given slope 
    y2_0 = max(data(:,2)-slope.*data(:,1));    
   
    if quad == 1 | quad == 2        
        % perpendicular line passes through y3_0 with given slope 
        y3_0 = max(data(:,2)+(1/slope).*data(:,1));        
        % last perpendicular line passes through y4_0 with given slope 
        y4_0 = min(data(:,2)+(1/slope).*data(:,1));
    elseif quad == 3 | quad == 4        
        % perpendicular line passes through y3_0 with given slope 
        y3_0 = min(data(:,2)+(1/slope).*data(:,1));        
        % last perpendicular line passes through y4_0 with given slope 
        y4_0 = max(data(:,2)+(1/slope).*data(:,1));    
    else
        error('something wrong')
    end
    
    % the distance between min- and max-lines.
    % We'll use this for determining how many evaluation points we want.
    % For example accuracy=100; 100 points for max-distance of asteroid
    % The distance between y1 and y2
    dis = abs(y1_0 - y2_0)/sqrt(slope^2+1);
    % The distance between y3 and y4
    dis2 = abs(y3_0 - y4_0)/sqrt((-1/slope)^2+1);
    
    % steps needed
    lines = ceil(dis*accuracy);
    
    % step sizes
    % differences between y-coordinates of consecutive lines
    y_line_step = dis/(lines*cos(pi/2-asin(1/sqrt(slope^2+1))));
    y_point_step = dis2/(lines*cos(pi/2-asin(1/sqrt((1/slope)^2+1))));
    
    % Initialations
    % in visible-array we save the coordinates of points, 
    % which reflects a light ray to the viewer. Count keeps track
    count = 1;
    visible = zeros(lines,2);
    
    % outer loop is for lines through asteroid
    for iii = 1:lines-1

        if quad == 1 || quad == 2        
            % perpendicular line passes through y3_0 with given slope 
            y3_0 = max(data(:,2)+(1/slope).*data(:,1));       
        elseif quad == 3 || quad == 4        
            % perpendicular line passes through y3_0 with given slope 
            y3_0 = min(data(:,2)+(1/slope).*data(:,1));
        else
            error('something wrong')
        end
        
        % line equation of the perpendicular line
        y3 = (-1/slope).*x1(:)+y3_0;
        
        % move line
        y1_0 = y1_0 + y_line_step;
        
        % We take the intersection point of y1 and y3 (x_int,y_int)
        % and start moving y3 towards the asteroid until the intersection
        % is inside the asteroid
        x_int = (y3_0 - y1_0)/(1/slope + slope);
        y_int = slope*x_int+y1_0;

        % At first the point is not inside the polygon
        inPolyg = 0;

        % this loop is for points scanning through the light ray
        % the loop runs until the intersection is in the polygon
        % then we check if it reflects to the viewer
        while(inPolyg==0)
    
            % Inside/outside test
            [in,on] = inpolygon(x_int,y_int,data(:,1),data(:,2));
            y_int_tmp = y_int;
            
            %%
            if in == 1 || on == 1
                inPolyg = 1;

                % this while loop finds out if the light ray reflects to the
                % viewer
                obstacle = 0;
                while obstacle == 0
                    y_int = y_int - 2*dis/accuracy;
                    [in,on] = inpolygon(x_int,y_int,data(:,1),data(:,2));
      
                    if in == 1 || on == 1
                        count = count + 1;
                        obstacle = 1;
                    else
                        if y_int < y_min
                            visible(count,1) = x_int;
                            visible(count,2) = y_int_tmp;
    
                            count = count + 1;
                            obstacle = 1;
                        end
                    end
                end
            else
                %%
                % the point is not inside the asteroid yet, so we move on
                % to the next point of the light ray
                if quad == 1 | quad == 2
                    if y3_0 > y4_0
                        y3_0 = y3_0 - y_point_step;
                        x_int = (y3_0 - y1_0)/(1/slope + slope);
                        y_int = slope*x_int+y1_0;
                    else
                        visible(count,1) = -10;
                        count = count + 1;
                        break
                    end
                elseif quad == 3 | quad == 4
                    if y3_0 < y4_0
                        y3_0 = y3_0 + y_point_step;
                        x_int = (y3_0 - y1_0)/(1/slope + slope);
                        y_int = slope*x_int+y1_0;
                    else
                        visible(count,1) = -10;
                        count = count + 1;
                        break
                    end
                else
                    error('something wrong')
                end
            end
        end
    end
    
    % Add length of projection to the light curve data
    proj_lengths(kkk) = projLength(visible,data);
    
    % Rotate the asteroid
    data = (rot*data.')';
    
    %disp([num2str(2*kkk),' % completed']);
    
end

% save proj_lengths
% plot(proj_lengths)
% text1 = ['Light rays: ',num2str(accuracy)];
% text(30,0.8,text1)