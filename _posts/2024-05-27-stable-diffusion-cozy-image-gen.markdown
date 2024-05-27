---
layout: post
title:  "Generating cozy AI art"
date:   2024-05-26 20:52:25
categories: ai art
image: 
---
It's almost the middle of 2024 and these days I'm really interested in these cozy AI studio ghilbi style anime illustrations generated using midjourney or stable diffusion. I think it started when all these ai art instagram pages started showing up on my feed and now I can't get enough of them.


So I started looking into how are these made and how can I make them on my own. I had some experience with AI art because back in 2021 when NFTs were the rage, I would mint AI art and sell it on WazirX NFT marketplace. That was a fun little thing to do. Anyways, tech has changed a lot since then and I had to do a lot of reading up on new stuff like Stable Diffusion. Here's what one of my images looks like:

<p align="center">
  <img src="/assets/cozy-ai-art.png" alt="a very detailed coffee shop from outside, with a big tree next to it, blue sky, road with pebbles on it, much much detailed, a night scene">
</p>

I got myself a `V100` Nvidia GPU and installed the [AUTOMATIC1111](https://github.com/AUTOMATIC1111/stable-diffusion) version of stable diffusion on it. I played around with so many models. I got the best results with using [Dreamshaper-XL](https://civitai.com/models/112902/dreamshaper-xl).

For the image generated above, I fed this as the positive prompt:
```
masterpiece, intricate details, hyperdetailed, hdr, best quality, 
colorful and vibrant, landscape, anime style, extremely detailed, cozy, 
illustration, lofi, comforting to look at, a very detailed coffee shop 
from outside, with a big tree next to it, blue sky, road with 
pebbles on it, much much detailed, a night scene
```

and for the negative prompt:
```
humans, explicit, sensitive, nsfw, low quality, worst quality,
bad anatomy, bad hands, text, error, missing fingers, extra digit, 
fewer digits, cropped, worst quality, low quality, normal quality, 
jpeg artifacts, signature, watermark, username, blurry, artist name
```

In my experience generating a 1024x1024 size image was good enough in reasonable time. But when I check the `highres` box and upscale by 2x, the details in the image are way better.

I used the stable diffusion API to deploy a webserver [here](https://rcher.ctrlb.ai). A new favourite activity on mine now is to image a scene in my head and try to recreate it using AI. It's fun!

Hopefully soon, I'll work on adding sounds and making a small looping video out of this.

