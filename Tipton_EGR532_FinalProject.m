%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: Final Project: Fovea and Optical Disc Localization
% Filename: Tipton_EGR532_FinalProject.m
% Author: Natalie Tipton
% Date: 4/18/19
% Instructor: Dr. Rhodes
% Description: This algorithm solves the prolem presented by IDRiD in their
%   challenge hosted on Grand Challenges in Image Processing. This will
%   take a folder with as many fundus scans of the retina as desired. It
%   will segment the optical disc and localize the optic disc and fovea by
%   finding the center points.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clear all variables and command window
clear; clc;

%obtain directory path from user
path = uigetdir('*.tif*');
orig_path = cd(path);    %change directory so MATLAB can find files
files = dir('IDRiD*.jpg*');   %open all .tif or .tiff files in directory with IS in name
mask = ismember({files.name}, {'.', '..'});
files(mask) = [];   %get rid of . and .. directories
[num_files,z] = size(files);    %determine number of files read

%complete loop for each image read from directory
for n = 1:num_files
    %after each image, clear all variables except cumulative data variables
    if n > 1
        clearvars -except im n numfiles files path orig_path centroid_od centroid_f
    end
    %read in all images in directory
    cd(path);
    im{n} = imread(files(n).name);
    cd(orig_path);
    
    %use nth image in directory for current analysis
    image = im{1,n};
    image = im2double(image);
    
    %obtain grayscale image
    image_gray = rgb2gray(image);
    [row, col] = size(image_gray);
    
    %obtain red plane of original image and perform histogram equalization
    red = image(:,:,1);
    red_eq = histeq(red);
    
    %blur equalized image, create a threshold, and binarize
    red_eq_blur = blur_gray(red_eq, 50);
    thresh_od = 0.99 * max(red_eq(:));
    bin_od = im2bw(red_eq_blur, thresh_od);
    
    %blur binarized image to reduce noise, create threshold, and binarize
    %again
    bin2_od = blur_gray(bin_od,10);
    thresh2_od = .9 * max(bin2_od(:));
    bin2_od = im2bw(bin2_od, thresh2_od);
    
    %fill in gaps in circular OD mask
    se = strel('disk',100);
    last_od = imclose(bin2_od,se);
    
    %remove all white regions aside from largest one
    od_mask = bwareafilt(last_od,1);
    
    %Place OD mask on top of original image
    for x = 1:row
        for y = 1:col
            for k = 1:3
                if od_mask(x,y) == 1
                    fin(x,y,k) = 1;
                else
                    fin(x,y,k) = image(x,y,k);
                end
            end
        end
    end
    
    %find centroid of OD
    s = regionprops(od_mask, 'centroid');
    centroid_od(n,:) = cat(1,s.Centroid);
    
    %create mask based on location of OD to find fovea
    %mask exists in range from 1200 to 1500 pixels to the side of the OD and
    %500 pixels above and below the OD location in the X range from above
    if centroid_od(n,1) < 2000        %if OD located on left side of image
        right_lim = centroid_od(n,1) + 1500;
        left_lim = centroid_od(n,1) + 1100;
        top_lim = centroid_od(n,2) + 500;
        bot_lim = centroid_od(n,2) - 500;
        for x = 1:row
            for y = 1:col
                if y < right_lim && y > left_lim
                    if x < top_lim && x > bot_lim
                        fovea_mask(x,y) = 1;
                    else
                        fovea_mask(x,y) = 0;
                    end
                else
                    fovea_mask(x,y) = 0;
                end
            end
        end
        
    else                          %if OD located on right side of image
        left_lim = centroid_od(n,1) - 1500;
        right_lim = centroid_od(n,1) - 1100;
        top_lim = centroid_od(n,2) + 500;
        bot_lim = centroid_od(n,2) - 500;
        for x = 1:row
            for y = 1:col
                if y < right_lim && y > left_lim
                    if x < top_lim && x > bot_lim
                        fovea_mask(x,y) = 1;
                    else
                        fovea_mask(x,y) = 0;
                    end
                else
                    fovea_mask(x,y) = 0;
                end
            end
        end
    end
    
    %aply mask to grayscale image
    fovea_loc = image_gray.* fovea_mask;
    
    %create threshold and binarize image to create mask over fovea location
    thresh = 1.1 * min(fovea_loc(fovea_loc~=0));
    for x = 1:row
        for y = 1:col
            if fovea_loc(x,y) < thresh && fovea_loc(x,y) ~= 0
                fovea_bin(x,y) = 1;
            else
                fovea_bin(x,y) = 0;
            end
        end
    end
    
    %blur original fovea mask, find another threshold and re-binarize
    fovea_bin = blur_gray(fovea_bin, 3);
    thresh_bin = 0.1 * max(fovea_bin(:));
    fovea_bin_fin = im2bw(fovea_bin, thresh_bin);
    
    %fill in gaps in circular region of fovea and remove all but largest
    %region
    se = strel('disk',25);
    last_fov = imclose(fovea_bin_fin,se);
    last_fov = bwareafilt(last_fov,1);
    
    %apply mask where fovea is located to the grayscale image
    fov_fin = image_gray .* last_fov;
    
    %find centroid of fovea
    s2 = regionprops(last_fov, 'centroid');
    centroid_f(n,:) = cat(1,s2.Centroid);
    
    %plot all steps of the algorith in images with titles and axis labels
    figure; imshow(image_gray);
    title('Grayscale Image');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(red);
    title('Red Plane');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(red_eq)
    title('Histogram Equalized Red Plane');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(bin_od)
    title('First OD Mask');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(bin2_od)
    title('Second OD Mask');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(last_od);
    title('Third OD Mask');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(od_mask);
    title('Final OD Mask');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(fovea_mask)
    title('Mask to Narrow Down Fovea Location');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(fovea_loc)
    title('View of Fovea From Mask');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(fovea_bin)
    title('First Mask of Fovea');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(fovea_bin_fin)
    title('Second Mask of Fovea');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(last_fov)
    title('Final Mask of Fovea');
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    figure; imshow(fin)
    hold on
    plot(centroid_od(:,1),centroid_od(:,2),'b*')
    plot(centroid_f(n,1),centroid_f(n,2),'b*')
    hold off
    title({'Final Results','OD Segmentation','Center Point of OD and Fovea'});
    xlabel('X (spatial units)'); ylabel('Y (spatial units)');
    
end

%round centroid (x,y) values
centroid_od = round(centroid_od);
centroid_f = round(centroid_f);

%export OD centroid data to a spreadsheet
T = table(centroid_od);
T(1:n,:);
filename = 'Project_Demo.xlsx';
writetable(T, filename, 'Sheet', 1, 'Range', 'A1');

%export fovea centroid data to same spreadsheet
T2 = table(centroid_f);
T2(1:n,:);
filename2 = 'Project_Demo.xlsx';
writetable(T2, filename2, 'Sheet', 1, 'Range', 'D1');




