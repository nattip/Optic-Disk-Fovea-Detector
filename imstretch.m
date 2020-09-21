function stretch = imstretch(im)

%This function contrast stretches the given image

min_value = min(im(im~=0));
max_value = max(im(:));

%find first expanded contrast image
stretch = (im-min_value).*(255/(max_value-min_value));