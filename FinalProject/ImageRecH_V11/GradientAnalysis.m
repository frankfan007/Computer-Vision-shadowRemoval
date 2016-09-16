% GradientAnalysis.m
%   Performs the analysis of gradient data generated by getGradient.m
%   D is the decomposition
%   X and Y are multigrid representations of the filtered X and Y data that
%   has use in the smoothing portion of synthesis.
% Reference:
%   P. Hampton, P. Agathoklis, C. Bradley, "A New Wave-Front Reconstruction 
%   Method for Adaptive Optics Systems Using Wavelets", IEEE Journal of 
%   Selected Topics in Signal Processing, vol. 2, no. 5, October 2008
% 
% Written by:  Peter Hampton
%   Copyright August 2008
% Commented by: Ioana Sevcenco

function [D, X, Y] = GradientAnalysis(dzdx,dzdy)
%% Truncates data size to avoid long delays or crashes due to memory allocation issues. 
% Delete this if you want data sets larger than 4 Mpixels
% [nr nc] = size(dzdx);
% if nr > 2047
%     dzdx = dzdx(1:2047,:);
%     dzdy = dzdy(1:2047,:);
% end
% if nc > 2047
%     dzdx = dzdx(:,1:2047);
%     dzdy = dzdy(:,1:2047);
% end
%%
[dzdx, dzdy] = Reflect(dzdx,dzdy);
M = ceil(log2(size(dzdx)));

M = max(M);
N = 2^M;
offset = 0.5*N;
m = 0:M;
iS = 2.^m + 1; % start index
iE = 2.^(m+1); % end index
iSD = ceil(2.^(m-1)) + 1;
iED = 2.^m;
X(1:iS(M+1)-1,iS(M+1):iE(M+1)) = dzdx;
Y(1:iS(M+1)-1,iS(M+1):iE(M+1)) = dzdy;
U = 0*dzdx;
V = 0*dzdy;
D = 0*dzdx;
for m = M:-1:1;
    
    U(1:iS(m)-2,iS(m):iE(m)-1) = X(1:2:iS(m+1)-3,iS(m+1):2:iE(m+1)-2) ...
                             + X(1:2:iS(m+1)-3,iS(m+1)+2:2:iE(m+1));
    U(iS(m):iE(m)-1,iS(m):iE(m)-1) = X(3:2:iS(m+1)-1,iS(m+1):2:iE(m+1)-2) ...
                             + X(3:2:iS(m+1)-1,iS(m+1)+2:2:iE(m+1));
    
    % HH

    D(iSD(m):iED(m),iSD(m):iED(m)) = (U(iS(m):2:iE(m)-1,iS(m):2:iE(m)-1) ...
                                   - U(1:2:iS(m)-2,iS(m):2:iE(m)-1))*0.5 ...
                                   + X(3:4:iS(m+1)-1,iS(m+1)+1:4:iE(m+1)-1) ...
                                   - X(1:4:iS(m+1)-3,iS(m+1)+1:4:iE(m+1)-1);
    
    % Lowpass filter and downsample X
    X(1:iS(m)-2,iS(m):iE(m)-1) = (U(1:iS(m)-2,iS(m):iE(m)-1) ... 
                               + U(iS(m):iE(m)-1,iS(m):iE(m)-1))*0.5 ...
                               + X(1:2:iS(m+1)-3,iS(m+1)+1:2:iE(m+1)-1) ...
                               + X(3:2:iS(m+1)-1,iS(m+1)+1:2:iE(m+1)-1);
    
    % Downsample again to obtain HL
    D(1:iS(m)-1,iS(m):iE(m)) = X(1:2:iS(m+1)-2,iS(m+1):2:iE(m+1)-1);

    V(1:iS(m)-2,iS(m):iE(m)-1) = Y(1:2:iS(m+1)-3,iS(m+1):2:iE(m+1)-2) ...
                               + Y(3:2:iS(m+1)-1,iS(m+1):2:iE(m+1)-2);
                           
    V(iS(m):iE(m)-1,iS(m):iE(m)-1) = Y(1:2:iS(m+1)-3,iS(m+1)+2:2:iE(m+1)) ...
                               + Y(3:2:iS(m+1)-1,iS(m+1)+2:2:iE(m+1));
    
    % Add solution from Y into HH
    D(iSD(m):iED(m),iSD(m):iED(m)) = D(iSD(m):iED(m),iSD(m):iED(m))...
                                   + (V(iS(m):2:iE(m)-1,iS(m):2:iE(m)-1) ...
                                   - V(1:2:iS(m)-2,iS(m):2:iE(m)-1))*0.5 ...
                                   + Y(2:4:iS(m+1)-2,iS(m+1)+2:4:iE(m+1)) ...
                                   - Y(2:4:iS(m+1)-2,iS(m+1):4:iE(m+1)-2);
    % Normalize the average
    D(iSD(m):iED(m),iSD(m):iED(m)) = D(iSD(m):iED(m),iSD(m):iED(m))*0.5;
                               
    % Low pass filter and downsample Y
    Y(1:iS(m)-2,iS(m):iE(m)-1) = (V(1:iS(m)-2,iS(m):iE(m)-1) ... 
                             + V(iS(m):iE(m)-1,iS(m):iE(m)-1))*0.5 ...
                             + Y(2:2:iS(m+1)-2,iS(m+1):2:iE(m+1)-2) ...
                             + Y(2:2:iS(m+1)-2,iS(m+1)+2:2:iE(m+1));
                         
    D(iS(m):iE(m),1:iS(m)-1) = Y(1:2:iS(m+1)-2,iS(m+1):2:iE(m+1)-1);
end
m = M;
U(1:iS(m)-2,iS(m):iE(m)-1) = X(1:2:iS(m+1)-3,iS(m+1):2:iE(m+1)-2) ...
    + X(3:2:iS(m+1)-1,iS(m+1):2:iE(m+1)-2);
U(iS(m):iE(m)-1,iS(m):iE(m)-1) = X(1:2:iS(m+1)-3,iS(m+1)+2:2:iE(m+1)) ...
    + X(3:2:iS(m+1)-1,iS(m+1)+2:2:iE(m+1));

% HH
D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m)) = ...
    (U(iS(m):2:iE(m)-1,iS(m):2:iE(m)-1) ...
    - U(1:2:iS(m)-2,iS(m):2:iE(m)-1))*0.5 ...
    + X(2:4:iS(m+1)-2,iS(m+1):4:iE(m+1)-2) ...
    - X(2:4:iS(m+1)-2,iS(m+1)+2:4:iE(m+1));

% Lowpass filter and downsample X
X(offset+1:offset+iS(m)-2,iS(m):iE(m)-1) = ...
     (U(1:iS(m)-2,iS(m):iE(m)-1) ...
    + U(iS(m):iE(m)-1,iS(m):iE(m)-1))*0.5 ...
    - X(2:2:iS(m+1)-2,iS(m+1):2:iE(m+1)-2) ...
    - X(2:2:iS(m+1)-2,iS(m+1)+2:2:iE(m+1));

% Downsample again to obtain HL

    V(1:iS(m)-2,iS(m):iE(m)-1) = Y(1:2:iS(m+1)-3,iS(m+1):2:iE(m+1)-2) ...
                               + Y(1:2:iS(m+1)-3,iS(m+1)+2:2:iE(m+1));
                           
    V(iS(m):iE(m)-1,iS(m):iE(m)-1) = Y(3:2:iS(m+1)-1,iS(m+1):2:iE(m+1)-2) ...
                               + Y(3:2:iS(m+1)-1,iS(m+1)+2:2:iE(m+1));
    
    % Add solution from Y into HH
    D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m)) = ...
        D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m))...
                                   + (V(iS(m):2:iE(m)-1,iS(m):2:iE(m)-1) ...
                                   - V(1:2:iS(m)-2,iS(m):2:iE(m)-1))*0.5 ...
                                   + Y(1:4:iS(m+1)-3,iS(m+1)+1:4:iE(m+1)-1) ...
                                   - Y(3:4:iS(m+1),iS(m+1)+1:4:iE(m+1)-1);
    % Normalize the average
    D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m)) = ...
        D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m))*0.5;

    % Low pass filter and downsample Y
    Y(offset+1:offset+iS(m)-2,iS(m):iE(m)-1) = (V(1:iS(m)-2,iS(m):iE(m)-1) ... 
                             + V(iS(m):iE(m)-1,iS(m):iE(m)-1))*0.5 ...
                              - Y(1:2:iS(m+1)-3,iS(m+1)+1:2:iE(m+1)-1) ...
                              - Y(3:2:iS(m+1)-1,iS(m+1)+1:2:iE(m+1)-1);


for m = M-1:-1:1;
    U(1:iS(m)-2,iS(m):iE(m)-1) = X(offset+1:2:offset+iS(m+1)-3,iS(m+1):2:iE(m+1)-2) ...
                             + X(offset+3:2:offset+iS(m+1)-1,iS(m+1):2:iE(m+1)-2);
    U(iS(m):iE(m)-1,iS(m):iE(m)-1) = X(offset+1:2:offset+iS(m+1)-3,iS(m+1)+2:2:iE(m+1)) ...
                             + X(offset+3:2:offset+iS(m+1)-1,iS(m+1)+2:2:iE(m+1));
    
    % HH
    D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m)) = ...
                                    (U(iS(m):2:iE(m)-1,iS(m):2:iE(m)-1) ...
                                   - U(1:2:iS(m)-2,iS(m):2:iE(m)-1))*0.5 ...
                                   + X(offset+2:4:offset+iS(m+1)-2,iS(m+1)+2:4:iE(m+1)) ...
                                   - X(offset+2:4:offset+iS(m+1)-2,iS(m+1):4:iE(m+1)-2);
    
    % Lowpass filter and downsample X
    X(offset+1:offset+iS(m)-2,iS(m):iE(m)-1) = (U(1:iS(m)-2,iS(m):iE(m)-1) ... 
                               + U(iS(m):iE(m)-1,iS(m):iE(m)-1))*0.5 ...
                               + X(offset+2:2:offset+iS(m+1)-2,iS(m+1):2:iE(m+1)-2) ...
                               + X(offset+2:2:offset+iS(m+1)-2,iS(m+1)+2:2:iE(m+1));
    
    % Downsample again to obtain HL
    D(offset+iS(m):offset+iE(m),offset+1:offset+iS(m)-1) = (X(offset+1:2:offset+iS(m+1)-2,iS(m+1):2:iE(m+1)-1));

    V(1:iS(m)-2,iS(m):iE(m)-1) = Y(offset+1:2:offset+iS(m+1)-3,iS(m+1):2:iE(m+1)-2) ...
                               + Y(offset+1:2:offset+iS(m+1)-3,iS(m+1)+2:2:iE(m+1));
                           
    V(iS(m):iE(m)-1,iS(m):iE(m)-1) = Y(offset+3:2:offset+iS(m+1)-1,iS(m+1):2:iE(m+1)-2) ...
                               + Y(offset+3:2:offset+iS(m+1)-1,iS(m+1)+2:2:iE(m+1));
    
    % Add solution from Y into HH
    D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m)) = ...
                                     D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m))...
                                   +(V(iS(m):2:iE(m)-1,iS(m):2:iE(m)-1) ...
                                   - V(1:2:iS(m)-2,iS(m):2:iE(m)-1))*0.5 ...
                                   + Y(offset+3:4:offset+iS(m+1)-1,iS(m+1)+1:4:iE(m+1)-1) ...
                                   - Y(offset+1:4:offset+iS(m+1)-3,iS(m+1)+1:4:iE(m+1)-1);
    % Normalize the average
    D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m)) = ...
        D(offset+iSD(m):offset+iED(m),offset+iSD(m):offset+iED(m))*0.5;
                               
    % Low pass filter and downsample Y
    Y(offset+1:offset+iS(m)-2,iS(m):iE(m)-1) = (V(1:iS(m)-2,iS(m):iE(m)-1) ... 
                             + V(iS(m):iE(m)-1,iS(m):iE(m)-1))*0.5 ...
                             + Y(offset+1:2:offset+iS(m+1)-3,iS(m+1)+1:2:iE(m+1)-1) ...
                             + Y(offset+3:2:offset+iS(m+1)-1,iS(m+1)+1:2:iE(m+1)-1);
                         
    D(offset+1:offset+iS(m)-1,offset+iS(m):offset+iE(m)) = Y(offset+1:2:offset+iS(m+1)-2,iS(m+1):2:iE(m+1)-1);
end
