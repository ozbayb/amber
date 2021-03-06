function [centroids,imCoreBW] = getFiberCentroids(imInput, SE, thresh)
% getFiberCentroids
% [centroids,imCoreBW] = getFiberCentroids(imInput, SE, thresh)
% Binarizes image and identifies centroid pixel coordinates of fiber cores
% based on a threshold
% [centroids,imCoreBW] = getFiberCentroids(imFiberImage);
%
% INPUTS:
% imFiberImage - Input image
% SE -      Structural element generated by strel function
% thresh -  Threshold level for identifying a peak as a core
%
% OUTPUTS:
% centroids - Core locations in image coordinates
% imCores - Output binary mask of fiber core locations in original
%           image coordinates structured by SE
%
% Author: Baris N. Ozbay, University of Colorado Denver
% Version: 1.0

% Apply threshold to input image
imInput(imInput<thresh) = 0;
% Suppress pixels near border
imInput = imclearborder(imInput,4);

% Generate binary file identifying regional maxima
BW = imregionalmax(imInput,4);

% Get fiber core indices and info
coreStruct  = regionprops(BW,'centroid')';
centroids = round(cat(1, coreStruct.Centroid));

% Generate images of centroids with core values
imCentBW = double(zeros(size(BW)));
for i = 1:length(coreStruct)
    imCentBW(centroids(i,2),centroids(i,1))=1;
end

% Generate disks to represent cores
imCoreBW = imbinarize(imdilate(imCentBW,SE));


