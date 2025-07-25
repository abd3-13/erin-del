# Fork difference

I recently forked Erin so I could add a delete function. The idea came to me while I was browsing through my videos using Erin — I found myself wanting to remove a few that I no longer needed. So, with the skills I have, I decided to give it a shot. I'm still learning, so go easy on the critique!

## Changes done
- added a go binary that accepts a /del-video post with filename from the ` visibleVideos[currentVideoIndex].url ` when hit with post it deletes the video and its json file
- added a new function in the  `src/App.js ` called "currentdelete" that send the post to the go binary
- added a delete button in the `BottomNavbar/index.jsx ` 

## Deploy
- copy sample.env to .env
- modifiy .env to your needs, make to change the PUBLIC_URL as caddy takes this value for serving where
- `docker compose up -d` to build the image and then run the container
_____________________________________________________________________________________

<p align="center">
    <h1 align="center">Erin</h1>
    <p align="center">
      Self-hostable TikTok feed for your clips
      <br />
      Make a TikTok feed with your own videos
   </p>
</p>

| | | |
|:-------------------------:|:-------------------------:|:-------------------------:|
|<img width="1604" src="/screenshots/SCREENSHOT-1.png"/> |  <img width="1604" src="/screenshots/SCREENSHOT-2.png"/> | <img width="1604" src="/screenshots/SCREENSHOT-3.png"/> |

## Introduction

Erin is a simple and self-hostable service that enables you to view your own clips using TikTok's well-known vertical swipe feed.
[A request was made on Reddit](https://www.reddit.com/r/selfhosted/comments/1dogl9d/selfhost_a_site_for_short_videos_like_tiktok/)
for a self-hostable app that can show filtered videos using TikTok's interface, so I made it.

## Features

Erin has all these features implemented :
- Display your own videos using TikTok's swipe feed
- Mask the videos you don't want to see in your feed\*
- Choose which feed (playlist) you want to play\*\*
- Autoplay your feed without even swiping
- Seek forward and backward using your keyboard, or using double taps
- Enter / Exit fullscreen using a double tap in the center
- Show video metadata using TikTok's UI\*\*\*
- Simple lazy-loading mechanism for your videos
- Automatic clip naming based on file name
- Simple and optional security using a master password
- Support for Horizontal and Vertical scroll direction
- Support for custom styling\*\*\*\*
- Support for HTTP and HTTPS
- Support for Docker / proxy deployment

On top of these, please note that Erin is only a React app powered entirely by [Caddy](https://github.com/caddyserver/caddy).
Caddy takes care of authentication, serving static files, and serving the React app all at once.

> \*: You can mask videos to hide them from your feed. Should you want to see which videos were masked, and even unmask them, you can long-press the `Mask` button, and the manager will open.

> \*\*: By default, Erin will create a random feed from all the videos in your folder and its subdirectories. However, if you would like to create custom feeds (playlists), you can create subdirectories and organize your videos accordingly. For example: `https://my-server.tld/directory-a` will create a feed from the videos located in the `/directory-a` directory, and it works with any path (so, nested folders are supported).

> \*\*\*: You can show a channel (with an avatar and name), a caption and a link for all your videos using a metadata file. The metadata file can be located anywhere inside your videos folder, and it must match its associated video's filename, while replacing the extension with JSON. For example: `my-video.mp4` can have its metadata in `my-video.json`. The metadata format [is shown here](/examples/video-metadata.json), and note that you can use raw HTML in the caption for custom styling and effects.

> \*\*\*\*: You can inject your own stylesheet to customize the appearance of the app by doing two things: 1) set `USE_CUSTOM_SKIN` to `true`, and 2) mount a `custom.css` file onto `/srv/custom.css` in your container.

For more information, read about [Configuration](#configuration).

## Deployment and Examples

Before proceeding, regardless of Docker, Docker Compose, or a standalone deployment, please make sure
that you have created a `videos` directory containing all your video files. Later on, this directory will
be made available to your instance of Erin (by binding a volume to your Docker container, or putting the directory
next to your Caddyfile).

### Deploy with Docker

You can run Erin with Docker on the command line very quickly.

You can use the following commands :

```sh
# Create a .env file
touch .env

# Edit .env file ...

# Option 1 : Run Erin attached to the terminal (useful for debugging)
docker run --env-file .env -p <YOUR-PORT-MAPPING> -v ./videos:/srv/videos:ro mosswill/erin

# Option 2 : Run Erin as a daemon
docker run -d --env-file .env -p <YOUR-PORT-MAPPING> -v ./videos:/srv/videos:ro mosswill/erin
```

> **Note :** A `sample.env` file is located at the root of the repository to help you get started

> **Note :** When using `docker run --env-file`, make sure to remove the quotes around `AUTH_ENABLED` and `AUTH_SECRET`, or else
your container might crash due to unexpected interpolation and type conversions operated by Docker behind the scenes.

### Deploy with Docker Compose

To help you get started quickly, a few example `docker-compose` files are located in the ["examples/"](examples) directory.

Here's a description of every example :

- `docker-compose.simple.yml`: Run Erin as a front-facing service on port 443, with environment variables supplied in the `docker-compose` file directly.

- `docker-compose.proxy.yml`: A setup with Erin running on port 80, behind a proxy listening on port 443.

When your `docker-compose` file is on point, you can use the following commands :
```sh
# Run Erin in the current terminal (useful for debugging)
docker-compose up

# Run Erin in a detached terminal (most common)
docker-compose up -d

# Show the logs written by Erin (useful for debugging)
docker logs <NAME-OF-YOUR-CONTAINER>
```

## Configuration

To run Erin, you will need to set the following environment variables in a `.env` file :

> **Note :** Regular environment variables provided on the commandline work too

> **Note :** A `sample.env` file is located at the root of the repository to help you get started

| Parameter               | Type      | Description                | Default |
| :---------------------- | :-------- | :------------------------- | ------- |
| `PUBLIC_URL`            | `boolean` | The public URL used to remotely access your instance of Erin. (Please include HTTP / HTTPS and the port if not standard 80 or 443. Do not include a trailing slash) (Read the [official Caddy documentation](https://caddyserver.com/docs/caddyfile/concepts#addresses)) | https://localhost        
| `AUTH_ENABLED`          | `string`  | Whether Basic Authentication should be enabled. (This parameter is case sensitive) (Possible values : true, false) | true |
| `AUTH_SECRET`           | `string`  | The secure hash of the password used to protect your instance of Erin. | Hash of `secure-password` |
| `APP_TITLE`             | `string`  | The custom title that you would like to display in the browser's tab. (Tip: You can use `[VIDEO_TITLE]` here if you want Erin to dynamically display the title of the current video.) | Erin - TikTok feed for your own clips |
| `AUTOPLAY_ENABLED`      | `boolean` | Whether autoplay should be enabled. (This parameter is case sensitive) (Possible values : true, false) | false |
| `PROGRESS_BAR_POSITION` | `string`  | Where the progress bar should be located on the screen. (This parameter is case sensitive) (Possible values : bottom, top) | bottom |
| `IGNORE_HIDDEN_PATHS`   | `boolean` | Whether all hidden files and directories (starting with a dot) should be ignored by Erin, and not loaded or scanned altogether | false |
| `SCROLL_DIRECTION`      | `string`  | The scroll direction of your video feed. (Possible values : vertical, horizontal ) | vertical |
| `USE_CUSTOM_SKIN`       | `boolean` | Whether a custom skin should be loaded on startup. (Possible values : true, false) | false |

> **Tip :** To generate a secure hash for your instance, use the following command :

```sh
docker run caddy caddy hash-password --plaintext "your-new-password"
```

> **Note :** When using `docker-compose.yml` environment variables, if your password hash contains dollar signs: double them all, or else the app will crash.
> For example : `$ab$cd$efxyz` becomes `$$ab$$cd$$efxyz`. This is due to caveats with `docker-compose` string interpolation system.

## Troubleshoot

Should you encounter any issue running Erin, please refer to the following common problems that may occur.

> If none of these matches your case, feel free to open an issue.

#### Erin is unreachable over HTTP / HTTPS

Erin sits on top of a Caddy web server.

As a result :
- You may be able to better troubleshoot the issue by reading your container logs.
- You can check the [official Caddy documentation regarding addresses](https://caddyserver.com/docs/caddyfile/concepts#addresses).
- You can check the [official Caddy documentation regarding HTTPS](https://caddyserver.com/docs/automatic-https).

Other than that, please make sure that the following requirements are met :

- If Erin runs as a standalone application without proxy :
    - Make sure your server / firewall accepts incoming connections on Erin's port.
    - Make sure your DNS configuration is correct. (Usually, such record should suffice : `A erin XXX.XXX.XXX.XXX` for `https://erin.your-server-tld`)
    - Make sure your `.env` file is well configured according to the [Configuration](#configuration) section.

- If Erin runs inside Docker / behind a proxy :
    - Perform the previous (standalone) verifications first.
    - Make sure that `PUBLIC_URL` is well set in `.env`.
    - Check your proxy forwarding rules.
    - Check your Docker networking setup.

In any case, the crucial part is [Configuration](#configuration) and reading the official Caddy documentation.

#### Erin says that no video was found on my server

For Erin to serve your video files, those must respect the following requirements :
- The file extension is one of `.mp4`, `.ogg`, `.webm`. (There are the only extensions supported by web browsers.)
- The files are located in `/srv/videos` on your Docker container using a volume.

To make sure that your videos are inside your Docker container and in the right place, you can :
- Run `docker exec -it <NAME-OF-YOUR-CONTAINER> sh`
- Inside the newly-opened shell, run : `ls /srv/videos`
- You should see your video files here. If not, then check your volume-binding.

If Erin is still unable to find your videos despite everything being well-configured, please open an issue
including the output of your browser's Javascript console and network tab when the request goes to `/media/`.
It may have to do with browser-caching, invalid configuration, or invalid credentials.

#### How can I add new videos to my feed?

For now, you should just put your new video files into your videos directory that is mounted with Docker.
Erin will automatically pick up these new files, and when you refresh your browser you'll see them.

#### How should I name my video files?

Erin will automatically translate your file name into a title to display on the interface.

The conversion operated is as follows :
- `-` becomes ` `
- `__` becomes ` - `

Here's a few examples to help you name your files :
- `Vegas-trip__Clip-1.mp4` becomes `Vegas trip - Clip 1`
- `Spanish-language__Lesson-1.mp4` becomes `Spanish language - Lesson 1`
- `Spiderman-1.ogg` becomes `Spiderman 1`

Finally, please refrain from using the `#` symbol in your filenames, as
it is a browser anchor, and it will prevent Erin from playing your files.

#### In what order will my files appear in the feed?

Erin randomly shuffles your video files on every browser refresh.

As a result, there is no specific order for your videos to appear.

#### Some of my videos seem to be missing or not loaded at all

For now, Erin will only attempt to retrieve the videos that have a supported extension.

Supported extensions are : `.webm`, `.mp4`, and `.ogg`.

However, please note that Safari doesn't seem to support `.ogg`, hence these videos will be ignored for Safari users.

Should you have any advice or idea to support more extensions (especially for Safari users), please feel free to open an issue.

#### My custom password doesn't work

There seems to be a few caveats when using Docker / Docker Compose with Caddy-generated password hashes.

These are the rules you should follow :
- If you deployed Erin using the Docker CLI, via the command `docker run ... --env-file .env ...`, then your `AUTH_SECRET` should have no quote at all, and all the dollar signs should stay as they are without escape or doubling
- If you deployed Erin using Docker Compose, via a `docker-compose.yml` file, then your `AUTH_SECRET` should have its dollar signs doubled. Example : `i$am$groot` becomes `i$$am$$groot`.

That said, remember that your password hash must be generated with the following command :

```sh
docker run caddy caddy hash-password --plaintext "your-new-password"
```


#### Something else

Please feel free to open an issue, explaining what happens, and describing your environment.

## Credits

Hey hey ! It's always a good idea to say thank you and mention the people and projects that help us move forward.

Big thanks to the individuals / teams behind these projects :
- [tik-tok-clone](https://github.com/cauemustafa/tik-tok-clone) : For the base TikTok UI and smooth interaction.
- [Caddy](https://github.com/caddyserver/caddy) : For the lightweight and powerful web server.
- The countless others!

And don't forget to mention Erin if you like it or if it helps you in any way!

