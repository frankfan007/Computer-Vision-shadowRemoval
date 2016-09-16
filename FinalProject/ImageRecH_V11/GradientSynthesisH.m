% GradientSynthesisH.m
% Performs the synthesis of gradient decomposition generated by GradientAnalysisH.m
% Inputs:
%   D = decomposition output of gradient analysis step;
%   X, Y = filtered and downsampled parts of the gradient, output of 
%          gradient analysis step;
%   averageData = scalar, should be 0 or 1
%                 set to 0 for no Poisson solver in synthesis
%                 set to 1 to include Poisson solver in synthesis
%   no_iter = number of iterations of Poisson solver
% Output:
%   D = reconstructed 2D array
% References: 
% 1. I. S. Sevcenco, P. Hampton, P. Agathoklis, "A wavelet based method 
% for image reconstruction from gradient data with applications", 
% Multidimensional Systems and Signal Processing, November 2013
% 
% 2. P. Hampton, P. Agathoklis, "Comparison of Haar Wavelet-based and Poisson-based
% Numerical Integration Techniques", 2010
% 
% 3. P. Hampton, P. Agathoklis, C. Bradley, "A New Wave-Front Reconstruction 
% Method for Adaptive Optics Systems Using Wavelets", IEEE Journal of 
% Selected Topics in Signal Processing, vol. 2, no. 5, October 2008
% 
% Written by: Peter Hampton, 2008
% Updated and commented by: Ioana Sevcenco,2012-2014
function D = GradientSynthesisH(D, X, Y, PoissonOn, no_iter)
if PoissonOn==0 && nargin < 5,
    no_iter = 0; % not used
end
if PoissonOn==1 && nargin < 5,
    no_iter = 3; % suggested number of iterations    
end;
Scrap = D;  
M = log2(max(size(D)));
twoPm = 1;
%% Top Left
iSq = 1:2*twoPm;
i1 = iSq(1:end/2);
i2 = iSq(1+end/2:end);
D(i1,i1) = D(i1,i1) - D(i2,i1);
D(i1,i2) = D(i1,i2) - D(i2,i2);
D(i1,i1) = 0.5*(D(i1,i1) - D(i1,i2));
D(i2,i1) = (D(i2,i1) - D(i2,i2));
D(i2,i1) = D(i2,i1) + D(i1,i1);
D(i2,i2) = D(i1,i2) + 2*D(i2,i2);
D(i1,i2) = D(i1,i2) + D(i1,i1);
D(i2,i2) = D(i2,i2) + D(i2,i1);
Scrap(iSq(1:2:end-1),iSq(1:2:end-1)) = D(i1,i1);
Scrap(iSq(1:2:end-1),iSq(2:2:end)) = D(i1,i2);
Scrap(iSq(2:2:end),iSq(1:2:end-1)) = D(i2,i1);
Scrap(iSq(2:2:end),iSq(2:2:end)) = D(i2,i2);
D(iSq,iSq) = Scrap(iSq,iSq);
for m = 1:M-2
    twoPm = 2^m;
%% Top Left
    iSq = 1:2*twoPm;
    i1 = iSq(1:end/2);
    i2 = iSq(1+end/2:end);
    D(i1,i1) = D(i1,i1) - D(i2,i1);
    D(i1,i2) = D(i1,i2) - D(i2,i2);
    D(i1,i1) = 0.5*(D(i1,i1) - D(i1,i2));
    D(i2,i1) = (D(i2,i1) - D(i2,i2));
    D(i2,i1) = D(i2,i1) + D(i1,i1);
    D(i2,i2) = D(i1,i2) + 2*D(i2,i2);
    D(i1,i2) = D(i1,i2) + D(i1,i1);
    D(i2,i2) = D(i2,i2) + D(i2,i1);
    Scrap(iSq(1:2:end-1),iSq(1:2:end-1)) = D(i1,i1);
    Scrap(iSq(1:2:end-1),iSq(2:2:end)) = D(i1,i2);
    Scrap(iSq(2:2:end),iSq(1:2:end-1)) = D(i2,i1);
    Scrap(iSq(2:2:end),iSq(2:2:end)) = D(i2,i2);
    D(iSq,iSq) = Scrap(iSq,iSq);
%% Average in Extra Data for top left
    if PoissonOn == true 
        ir = 1:2*twoPm-1;
        ic = 2*twoPm + ir;
        iSq = 1:2*twoPm;    
        for ii = 1:no_iter, 
           D(iSq,iSq) = PoissonSolveExtend(D(iSq,iSq),X(ir,ic),Y(ir,ic));
        end
    end
end
m = M-1;
twoPm = 2^m;
%% Full image
iSq = 1:2*twoPm;
i1 = iSq(1:end/2);
i2 = iSq(1+end/2:end);
D(i2,i2) = Scrap(i2,i2); % change HH to the one obtained in new analysis
D(i1,i1) = D(i1,i1) - D(i2,i1);
D(i1,i2) = D(i1,i2) - D(i2,i2);
D(i1,i1) = 0.5*(D(i1,i1) - D(i1,i2));
D(i2,i1) = (D(i2,i1) - D(i2,i2));
D(i2,i1) = D(i2,i1) + D(i1,i1);
D(i2,i2) = D(i1,i2) + 2*D(i2,i2);
D(i1,i2) = D(i1,i2) + D(i1,i1);
D(i2,i2) = D(i2,i2) + D(i2,i1);
Scrap(iSq(1:2:end-1),iSq(1:2:end-1)) = D(i1,i1);
Scrap(iSq(1:2:end-1),iSq(2:2:end)) = D(i1,i2);
Scrap(iSq(2:2:end),iSq(1:2:end-1)) = D(i2,i1);
Scrap(iSq(2:2:end),iSq(2:2:end)) = D(i2,i2);
D(iSq,iSq) = Scrap(iSq,iSq);
%% Full image
if PoissonOn == true
    ir = 1:2*twoPm-1;
    ic = 2*twoPm + ir;
    iSq = 1:2*twoPm;
    for ii = 1:no_iter,       
        D(iSq,iSq) = PoissonSolveExtend(D(iSq,iSq),X(ir,ic),Y(ir,ic));
    end;
end       
end