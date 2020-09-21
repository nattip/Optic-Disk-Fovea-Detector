function im_blur = blur(im, neighbor)

%This function blurs a given image using a neighborhood averaging filter
%with neighborhood size determined by input variable

  im_blur = conv2(im, ones(neighbor,neighbor)/(neighbor^2), 'same');
