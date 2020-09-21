function im_blur = blur_color(im, neighbor)

%This function blurs a given image using a neighborhood averaging filter
%with neighborhood size determined by input variable

for k = 1 : size(im, 3)    %goes up to the length of the 3rd dimension
  im_blur(:,:,k) = conv2(im(:,:,k), ones(neighbor,neighbor)/(neighbor^2), 'same');
end