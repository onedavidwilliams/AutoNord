## License and Use

This software is available under the following terms:

- **For Learning Purposes:** Individuals may freely use and modify this software for personal learning and educational purposes without prior permission. I encourage you to dive into the code, learn, and share your knowledge with others.

- **Other Uses:** Use of this software for commercial purposes, contributions to commercial projects, or any use outside of personal learning requires prior explicit permission from the author(s). Please contact me at deltaflyerguy5@gmail.com
   to discuss licensing arrangements.

# Welcome to the Alpha Stage of My Bash Script Adventure

Hey there! You've stumbled upon a little project of mine that's currently in the alpha stage. It's all about giving you the power to monitor your network speeds and play around with VPN connections, all from the comfort of your terminal. 
I've thrown in a bunch of comments throughout the script to help you learn a bit quicker, whether you're aiming to impress your boss, land a job, or just enrich your learning experience.

## What's This Script All About?

In its current form, this bash script lets you:

- **Find Your Active Network Interface**: Handy for those times you need to figure out which interface is currently in use, without having to dig through your system settings.
- **Monitor Network Speed**: Ever wonder how fast your internet connection really is? This script keeps an eye on your download and upload speeds, saving the data for your perusal.
- **Manage VPN Connections**: With built-in functions to connect to different VPN servers, it's perfect for anyone looking to ensure their online activities remain private.
- **Randomly Select Contries and Cities** You can select 1337 Mode and it will randomly pict a city and country dynamically from nords database.
- **Manually Select Countries and Cities** You can choose which country or city you would like from the selection screen.
- **Manually/Randomly Select groups** The same as city and country you caneither choose a group (like the p2p, dedicated IP, onion over vpn, regions ect.)
- **Just Hitting Enter** Will select a P2P procol for torrenting networks as default.

  **TODO:**
  - I want to add a setting that users can, after a pre determined amount of time, jump to a different location around the world automatically. This will involve implementing and controlling and checking the killswitch behavior settings from bash.
  - I would also like to implement a save file so settings can be loaded immediately on start.
  - Take advantage of some of the proxy features of nord and their meshnet for direct connections.
And since we're all about learning here, I've made sure to explain how each part of the script works, right there in the comments.

## Getting Started

1. **Clone the repo**: Grab a copy of this script and get it on your machine.\
   **Direct Download** `curl -OJL https://raw.githubusercontent.com/g0n3b4d/AutoNord/main/AutoNord.sh && chmod +x AutoNord.sh`\
   **Direct Download & Run (this is unsafe unless you ABSOLUTELY TRUST THE PERSON)** `curl -OJL https://raw.githubusercontent.com/g0n3b4d/AutoNord/main/AutoNord.sh && chmod +x AutoNord.sh && ./AutoNord.sh`
3. **Make it executable**: Run `chmod +x AutoNord.sh` to make sure you can run it.
4. **Launch it**: Just type `./AutoNord.sh` into your terminal and follow the prompts.
![Screenshot from 2024-03-13 19-44-37](https://github.com/g0n3b4d/AutoNord/assets/40129462/b3ded4eb-d873-441d-b323-4dcd82dec629)
![Screenshot from 2024-03-13 19-44-48](https://github.com/g0n3b4d/AutoNord/assets/40129462/84beb2fe-21df-4950-9a99-05c82b63aacf)
![Screenshot from 2024-03-13 22-17-13](https://github.com/g0n3b4d/AutoNord/assets/40129462/fe7e851e-5551-4608-914b-105ae6f2e20e)


**These are screenshots**
- Will fix the entire country and name being displayed. I had it fixed but it was a completely terrible way to do it that no one should learn so I took it off. it has to do with formatting the spaces after the awk

## Using This Script

Feel free to dive into the code, tweak it, break it, fix it, and learn from it. If you're using it for anything beyond personal learning, especially if you're thinking about incorporating it into a commercial project, I'd appreciate a heads up. 
Just shoot me a message!
