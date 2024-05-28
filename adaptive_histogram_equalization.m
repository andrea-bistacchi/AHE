% @ 2019 by Andrea Bistacchi, distributed under the GNU AGPL v3.0 license.
%
% Adaptive histogram equalization in HSV color space of a collection of images stored in a directroy
%
% Last update by Andrea Bistacchi 28/5/2024

function adaptive_histogram_equalization

% initialize including parallel pool (if not yet active)
clear all; close all; clc; clearvars;
if isempty(gcp('nocreate')), parpool('Threads',gpuDeviceCount("available")); end

% file overwrite warning
disp(' ')
disp('---- WARNING: this script overwrites output files without asking for confirmaton ----')

% select input directory
input_directory = uigetdir;
disp(' ')
disp('adaptive_histogram_equalization started on directory:')
disp(input_directory)

% get tif and jpg files
input_tif_files = dir([input_directory '/*.tif']);
input_jpg_files = dir([input_directory '/*.jpg']);
input_files = [input_tif_files input_jpg_files];

% white sky option
while 1
    commandwindow
    disp(' ')
    ws_option = input('Make sky white y/n [n]:', 's');
    if isempty(ws_option), ws_option = 'n'; end
    if ws_option == 'y' || ws_option == 'n', break; end
end

if ws_option == 'y'
    % parameters for white sky correction
    disp(' ')
    threshold = input(['Lab channel B threshold 0->1 lower is stronger [0.69]: ']);
    if not(isnumeric(threshold))
        threshold = 0.69;
    elseif threshold < 0
        threshold = 0.69;
    elseif threshold > 1
        threshold = 0.69;
    elseif isempty(threshold)
        threshold = 0.69;
    end
    disp(' ')
    min_area = input('Minimum sky area pixels [1000000]: ');
    if not(isnumeric(min_area))
        min_area = 1000000;
    elseif min_area < 0
        min_area = 1000000;
    elseif isempty(min_area)
        min_area = 1000000;
    end
end

% choose output format
while 1
    disp(' ')
    disp('Output format [1]:')
    disp('   1: JPG (quality = 100)')
    disp('   2: PNG (no compression)')
    commandwindow
    out_format = input('>> ');
    if isempty(out_format), out_format = 1; end
    if out_format == 1 || out_format == 2, break; end
end

% parallel loop for input files
parfor i = 1:length(input_files)
    file_in = [input_directory '\' input_files(i).name];
    [filepath,filename,~] = fileparts(file_in);
    image_in = imread(file_in);
    if ws_option == 'y'
        image_in = white_sky(image_in, threshold, min_area)
    end
    image_out = adapteq(image_in);

    if out_format ==1
        if ws_option == 'y'
            file_out = [filepath '/' filename '_ws_eq.jpg'];
        else
            file_out = [filepath '/' filename '_eq.jpg'];
        end
        imwrite(image_out,file_out,'jpg','Quality',100);
    else
        if ws_option == 'y'
            file_out = [filepath '/' filename '_ws_eq.png'];
        else
            file_out = [filepath '/' filename '_eq.png'];
        end
        imwrite(image_out,file_out,'png');
    end
    disp(['Saved image: ' num2str(i)])
end
end

%% adaptive histogram equalization in HSV color space

function image_out = adapteq(image_in)

HSV = rgb2hsv(image_in);
HSV(:,:,3) = adapthisteq(HSV(:,:,3));
image_out = hsv2rgb(HSV);

end

%% white sky
% inpired by https://it.mathworks.com/matlabcentral/answers/1683379-how-can-i-detect-sky
% and https://it.mathworks.com/help/releases/R2021a/images/ref/regionprops.html?s_tid=doc_srchtitle#buorh68-1

function image_out = white_sky(image_in, threshold, min_area)

% threshold on Lab b channel (blue vs yellow)
image_lab = rgb2lab(image_in);
image_sky = imcomplement(mat2gray(image_lab(:,:,3)));
image_sky_mask = im2bw(image_sky, threshold);

% extract large connected components only
CC = bwconncomp(image_sky_mask);
stats = regionprops(CC,'Area');
idx = find([stats.Area] >= min_area);
image_sky_mask = ismember(labelmatrix(CC),idx);

r = image_in(:,:,1);
g = image_in(:,:,2);
b = image_in(:,:,3);
r(image_sky_mask) = 255;
g(image_sky_mask) = 255;
b(image_sky_mask) = 255;
image_out = cat(3,r,g,b);

end
