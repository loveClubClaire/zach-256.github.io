---
layout: page
permalink: "/code/vinylscrobbler/importpy" 
title: import.py
---

<a href="/code/vinylscrobbler/import.py">Download Link</a>
{% highlight python%}
import warnings
import json
warnings.filterwarnings("ignore")

from dejavu import Dejavu
from dejavu.recognize import FileRecognizer

# load config from a JSON file (or anything outputting a python dictionary)
with open("dejavu.cnf.SAMPLE") as f:
    config = json.load(f)

if __name__ == '__main__':
    
    # create a Dejavu instance
    djv = Dejavu(config)
        
    # Fingerprint all the mp3's in the directory we give it
    djv.fingerprint_directory("mp3", [".mp3","m4a"])

{% endhighlight %}