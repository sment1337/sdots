import os
import subprocess
import random
import requests
from bs4 import BeautifulSoup

def scrapeClass(url, html_class):
    # Make a request to the website
    response = requests.get(url)
    
    # Create a BeautifulSoup object and specify the parser
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find all elements with the class "gallery__link" for example
    links = soup.find_all(class_=html_class)
    
    # Extract the href values from the elements
    hrefs = [link.get('href') for link in links]
    return hrefs

if __name__ == "__main__":
    # first get rid of old images
    flist = [n for n in os.listdir() if '.jpg' in n]
    [os.remove(n) for n in flist] 

    url = 'https://gtgraphics.de/en/wallpapers'
    hrefs = scrapeClass(url, 'gallery__link')

    rand_index = random.randint(0,len(hrefs))
    print(hrefs[rand_index])
    ndx = hrefs[rand_index]
    subURL = ndx.split('/en/wallpapers')[1]
    downloadLinks = scrapeClass(url+subURL, 'download')
    imageURL = [n for n in downloadLinks if '1920x1080' in n][0]
    imageURL = imageURL.split(subURL)[1]
    subprocess.run(['wget', '-O', 'BG.jpg', url+subURL+imageURL])
    subprocess.run(['nitrogen', '--set-zoom-fill', 'BG.jpg'], stdout=subprocess.PIPE).stdout.decode('UTF8')
    #import ipdb; ipdb.set_trace(context=7)
