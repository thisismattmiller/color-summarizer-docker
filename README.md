# color-summarizer-docker
This runs the colorsummarizer on a directory you specify. 

To use:


```

docker pull thisismattmiller/colorsummarizer
docker run -it -v ~/Downloads:/usr/images thisismattmiller/colorsummarizer

```
The `-v ~/Downloads:/usr/images` part tells the script what directory to run the tool on. So here I am running it on all the *.jpg in my Downloads folder. You can then pipe the results of this command to a file.

If you want to stop the script (if it is running on a lot of files) in another window:

```

docker ps
docker kill <container_id_here>
```


 # To Build
```
git clone https://github.com/thisismattmiller/color-summarizer-docker.git
cd color-summarizer-docker
docker build -t colorsummarizer .
```

You can modify the `Dockerfile` on line 18 to make colorsumarizer do what you want:
```
Usage:
      # output format XML, text or JSON
      colorsummarizer -image img/ferns-100.jpg -xml
      colorsummarizer -image img/ferns-100.jpg -text
      colorsummarizer -image img/ferns-100.jpg -json

      # get image size
      colorsummarizer -image img/ferns-100.jpg -info

      # process all images in a directory
      colorsummarizer -dir "images/*jpg"

      # resize input image
      colorsummarizer -image img/ferns-100.jpg -width 50 -text

      # crop input image before resizing, horizontally by 20 pixels and vertically by 10 pixels
      colorsummarizer -image img/ferns-100.jpg -width 50 -cropx 20 -cropy 10  -text

      # crop left by 20, right by 50, top by 10 and bottom by 30
      colorsummarizer -image img/ferns-100.jpg -width 50 -cropx 20,50 -cropy 10,30  -text

      # extract a rectangle from the image with top left corner at (20,10) and 
      # width 50 and height 100
      colorsummarizer -image img/ferns-100.jpg -width 50 -cropx 20 -cropw 50 -cropy 10 -croph 100 -text

      # crop input image before resizing by 25 pixels on all sides
      colorsummarizer -image img/ferns-100.jpg -width 50 -crop 25 -text

      # interpret the images as a grid of images and analyze each one independently
      colorsummarizer -image img/ferns-100.jpg -grid 2,3

      # include histogram data
      colorsummarizer -image img/ferns-100.jpg -text -histogram

      # include raw pixel data
      colorsummarizer -image img/ferns-100.jpg -text -pixel

      # include aggregate statistics for each color space channel
      colorsummarizer -image img/ferns-100.jpg -text -stats

      # include image uniformity statistics across radius RADIUS (pixels)
      colorsummarizer -image img/ferns-100.jpg -text -uniformity RADIUS

      # combine outputs
      colorsummarizer -image img/ferns-100.jpg -text -stats -histogram

      # all stats
      colorsummarizer -image img/ferns-100.jpg -text -all

      # include color cluster data for k=5 clusters
      colorsummarizer -image img/ferns-100.jpg -text -clusters 5

      # clip pixels with transparency when clustering
      colorsummarizer -image img/ferns-100.jpg -text -clusters 5 -clip transparent

      # do not include names of nearest colors
      colorsummarizer -image img/ferns-100.jpg -text -clusters 5 -clip transparent -no-names

      # clip other kinds of pixels when clustering (e.g. black, white, green)
      colorsummarizer -image img/ferns-100.jpg -text -clusters 5 -clip transparent,white,black,green

      # create images from each color cluster in directory DIR
      # if DIR is not specified, then directory of the image will be used
      colorsummarizer -image img/ferns-100.jpg -text -clusters 5 -clip transparent,white,black,green -clusterimage DIR

      # use configuration
      colorsummarizer -conf colorsummarizer.conf

      # dump configuation
      colorsummarizer -cdump

      # print debugging information
      colorsummarizer -debug

      # print timings
      colorsummarizer -timer
```
