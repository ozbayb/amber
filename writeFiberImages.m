function writeFiberImages(folderName,baseFilename,bitDepth,inputProperties,varargin)
% writeFiberImages
% writeFiberImages(folderName,baseFilename,bitDepth,inputProperties,varargin)
% Writes images to files at specified bitdepth with the prefix of
% baseFilename and a suffix equivalent to the variable name. This code will
% attempt to apply relevant metadata to the output *.tif files.
%
% DEPENDENCIES:
% bioformats_package.jar
% https://docs.openmicroscopy.org/bio-formats/5.7.2/users/matlab/index.html
%
% INPUTs:
% folderName - String for output folder path
% baseFileName - String for base file name
% bitDepth -    Integer that specifies either 8 or 16 bit output image
% inputProperties - Struct of properties for original file for tif metadata
%   Fields:
%   -> frameTime (frame time in seconds, field empty if not time series)
%   -> umWidth   (width of original image in microns)
%   -> umHeight  (height of original image in microns)
%   -> stepSize  (Z-dimension step size in microns)
% varargin -    List of images to write to files
%
% OUTPUTS:
% N/A
%
% Author: Baris N. Ozbay, University of Colorado Denver
% Version: 1.0


if bitDepth~=8 && bitDepth~=16
    warning('bitDepth is not 8 or 16, defaulting to 8');
    bitDepth = 8;
end

if strcmp(folderName(end),'\')
    saveFolderName = [folderName];
else
    saveFolderName = [folderName,'\'];
end
mkdir(saveFolderName);

numFiles = nargin-4;

disp(inputProperties);
compressionType = 'Uncompressed';

% If there is no frameTime field assume that the stack is not a time series
if ~isnan(inputProperties.frameTime)
    tSeries=1;
else
    tSeries=0;
end

switch bitDepth
    case 8
        for ii = 1:numFiles
            imageToWrite = varargin{ii};
            variableName = inputname(ii+4);
            if max(imageToWrite(:))>1
                warning('Max value of %s is %d and will be clipped',variableName,max(imageToWrite(:)));
            end
            imageToWrite = uint8(imageToWrite*2^8-1);
            filenameToWrite = [baseFilename,'_',variableName];
            fullFilePath = [saveFolderName,'\',filenameToWrite,'.tif'];
            numImages = size(imageToWrite,3);
            % Get pixel dimensions
            umWidthPixel = inputProperties.umWidth/size(imageToWrite,2);
            umHeightPixel = inputProperties.umHeight/size(imageToWrite,1);

            if tSeries
                % Save using Bio-Formats OME
                umWidthOME = ome.units.quantity.Length(java.lang.Double(umWidthPixel), ome.units.UNITS.MICROMETER);
                umHeightOME = ome.units.quantity.Length(java.lang.Double(umHeightPixel), ome.units.UNITS.MICROMETER);
                umDepthOME = ome.units.quantity.Length(java.lang.Double(1), ome.units.UNITS.MICROMETER);
                frameTimeOME = ome.units.quantity.Time(java.lang.Double(inputProperties.frameTime/1e3), ome.units.UNITS.SECOND);
                metadata = createMinimalOMEXMLMetadata(imageToWrite);
                metadata.setPixelsPhysicalSizeX(umWidthOME, 0);
                metadata.setPixelsPhysicalSizeY(umHeightOME, 0);
                metadata.setPixelsPhysicalSizeZ(umDepthOME, 0);
                metadata.setPixelsTimeIncrement(frameTimeOME, 0);
                bfsave(imageToWrite, fullFilePath,...
                    'dimensionorder', 'XYTZC', 'metadata', metadata, 'compression',compressionType);
                % Re-open file and write imageJ metadata
                f=Tiff(fullFilePath, 'r+');
                newid=['ImageJ=1.51s' newline];
                newid=[newid 'images=' num2str(1) newline];
                newid=[newid 'channels=' num2str(1) newline];
                newid=[newid 'slices=' num2str(1) newline];
                newid=[newid 'frames=' num2str(numImages) newline];
                newid=[newid 'finterval=' num2str(inputProperties.frameTime/1e3) newline];
                newid=[newid 'unit=um' newline];
                newid=[newid 'spacing=' num2str(1) newline];
                newid=[newid 'loop=false' newline];
                setTag(f, 'ImageDescription', newid);
                f.rewriteDirectory();
                f.close();
            else
                % Save using Bio-Formats OME
                umWidthOME = ome.units.quantity.Length(java.lang.Double(umWidthPixel), ome.units.UNITS.MICROMETER);
                umHeightOME = ome.units.quantity.Length(java.lang.Double(umHeightPixel), ome.units.UNITS.MICROMETER);
                umDepthOME = ome.units.quantity.Length(java.lang.Double(inputProperties.stepSize), ome.units.UNITS.MICROMETER);
                frameTimeOME = ome.units.quantity.Time(java.lang.Double(1), ome.units.UNITS.SECOND);
                metadata = createMinimalOMEXMLMetadata(imageToWrite);
                metadata.setPixelsPhysicalSizeX(umWidthOME, 0);
                metadata.setPixelsPhysicalSizeY(umHeightOME, 0);
                metadata.setPixelsPhysicalSizeZ(umDepthOME, 0);
                metadata.setPixelsTimeIncrement(frameTimeOME, 0);
                bfsave(imageToWrite, fullFilePath,...
                    'dimensionorder', 'XYZTC', 'metadata', metadata, 'compression',compressionType);
                % Re-open file and write imageJ metadata
                f=Tiff(fullFilePath, 'r+');
                newid=['ImageJ=1.51s' newline];
                newid=[newid 'images=' num2str(1) newline];
                newid=[newid 'channels=' num2str(1) newline];
                newid=[newid 'slices=' num2str(numImages) newline];
                newid=[newid 'frames=' num2str(1) newline];
                newid=[newid 'finterval=' num2str(1) newline];
                newid=[newid 'unit=um' newline];
                newid=[newid 'spacing=' num2str(inputProperties.stepSize) newline];
                newid=[newid 'loop=false' newline];
                setTag(f, 'ImageDescription', newid);
                f.rewriteDirectory();
                f.close();
            end
        end
    case 16
        for ii = 1:numFiles
            imageToWrite = varargin{ii};
            variableName = inputname(ii+4);
            if max(imageToWrite(:))>1
                warning('Max value of %s is %d and will be clipped',variableName,max(imageToWrite(:)));
            end
            imageToWrite = uint16(imageToWrite*2^16-1);
            filenameToWrite = [baseFilename,'_',variableName];
            fullFilePath = [saveFolderName,'\',filenameToWrite,'.tif'];
            numImages = size(imageToWrite,3);
            % Get pixel dimensions
            umWidthPixel = inputProperties.umWidth/size(imageToWrite,2);
            umHeightPixel = inputProperties.umHeight/size(imageToWrite,1);

            if tSeries
                % Save using Bio-Formats OME
                umWidthOME = ome.units.quantity.Length(java.lang.Double(umWidthPixel), ome.units.UNITS.MICROMETER);
                umHeightOME = ome.units.quantity.Length(java.lang.Double(umHeightPixel), ome.units.UNITS.MICROMETER);
                umDepthOME = ome.units.quantity.Length(java.lang.Double(1), ome.units.UNITS.MICROMETER);
                frameTimeOME = ome.units.quantity.Time(java.lang.Double(inputProperties.frameTime/1e3), ome.units.UNITS.SECOND);
                metadata = createMinimalOMEXMLMetadata(imageToWrite);
                metadata.setPixelsPhysicalSizeX(umWidthOME, 0);
                metadata.setPixelsPhysicalSizeY(umHeightOME, 0);
                metadata.setPixelsPhysicalSizeZ(umDepthOME, 0);
                metadata.setPixelsTimeIncrement(frameTimeOME, 0);
                bfsave(imageToWrite, fullFilePath,...
                    'dimensionorder', 'XYTZC', 'metadata', metadata, 'compression',compressionType);
                % Re-open file and write imageJ metadata
                f=Tiff(fullFilePath, 'r+');
                newid=['ImageJ=1.51s' newline];
                newid=[newid 'images=' num2str(1) newline];
                newid=[newid 'channels=' num2str(1) newline];
                newid=[newid 'slices=' num2str(1) newline];
                newid=[newid 'frames=' num2str(numImages) newline];
                newid=[newid 'finterval=' num2str(inputProperties.frameTime/1e3) newline];
                newid=[newid 'unit=um' newline];
                newid=[newid 'spacing=' num2str(1) newline];
                newid=[newid 'loop=false' newline];
                setTag(f, 'ImageDescription', newid);
                f.rewriteDirectory();
                f.close();
            else
                % Save using Bio-Formats OME
                umWidthOME = ome.units.quantity.Length(java.lang.Double(umWidthPixel), ome.units.UNITS.MICROMETER);
                umHeightOME = ome.units.quantity.Length(java.lang.Double(umHeightPixel), ome.units.UNITS.MICROMETER);
                umDepthOME = ome.units.quantity.Length(java.lang.Double(inputProperties.stepSize), ome.units.UNITS.MICROMETER);
                frameTimeOME = ome.units.quantity.Time(java.lang.Double(1), ome.units.UNITS.SECOND);
                metadata = createMinimalOMEXMLMetadata(imageToWrite);
                metadata.setPixelsPhysicalSizeX(umWidthOME, 0);
                metadata.setPixelsPhysicalSizeY(umHeightOME, 0);
                metadata.setPixelsPhysicalSizeZ(umDepthOME, 0);
                metadata.setPixelsTimeIncrement(frameTimeOME, 0);
                bfsave(imageToWrite, fullFilePath,...
                    'dimensionorder', 'XYZTC', 'metadata', metadata, 'compression',compressionType);
                % Re-open file and write imageJ metadata
                f=Tiff(fullFilePath, 'r+');
                newid=['ImageJ=1.51s' newline];
                newid=[newid 'images=' num2str(1) newline];
                newid=[newid 'channels=' num2str(1) newline];
                newid=[newid 'slices=' num2str(numImages) newline];
                newid=[newid 'frames=' num2str(1) newline];
                newid=[newid 'finterval=' num2str(1) newline];
                newid=[newid 'unit=um' newline];
                newid=[newid 'spacing=' num2str(inputProperties.stepSize) newline];
                newid=[newid 'loop=false' newline];
                setTag(f, 'ImageDescription', newid);
                f.rewriteDirectory();
                f.close();
            end
        end
end