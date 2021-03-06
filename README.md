# Playbox for [Übersicht](http://tracesof.net/uebersicht/)

<img src="https://github.com/Pe8er/Playbox.widget/blob/master/screenshot.jpg" width="516" height="320">

## [Download](https://github.com/Pe8er/Playbox.widget/raw/master/Playbox.widget.zip)

This widget shows currently played song in either iTunes or Spotify. It has a spiffy progress bar, shows pretty artwork (external dependency: pretty artwork) and last but not least: it comes in **three variants**!

## Features

- Supports both Spotify and iTunes
- Shows artwork (courtesy of [last.fm](http://www.last.fm))
- Progress bar
- Three size variants
- Easy way to toggle the widget's visibility
- Easy way to position the widget on the screen
- Spiffy fade animation on pause

## Options

Here's how you can set all the widget's options. Open `index.coffee` and look at the very beginning:

```coffeescript
options =
  # Easily enable or disable the widget.
  widgetEnable : true

  # Choose your widget.
  widgetVariant: "small"          # large | medium | small

  # Stick the widget in the corner? Set to *true* if you're using it with Sidebar widget, set to *false* if you'd like to give it some breathing room and a drop shadow.
  stickInCorner: true

  # Choose where the widget should sit on your screen.
  vPosition    : "top"            # top | bottom | center
  hPosition    : "bottom"         # left | right | center
```

[See my other widgets](https://github.com/Pe8er/Ubersicht-Widgets)