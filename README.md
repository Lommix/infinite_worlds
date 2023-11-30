# Infinite Worlds

Godot addon for generating infinite growing terrain using Wave-Function-Collapse algorithm.

[demo](docs/demo.webm)

How cool would it be. Draw some tiles, define some simple rules and an infinite world awaits you!

Well this addon makes it possible. It uses the Wave-Function-Collapse algorithm to generate the world.

All you have to do, is draw some patterns on a reference tilemap and use the inbuild editor tool to generate a wave function collapse ruleset from that.

Then plug it into a special tilemap node and you are good to go.

![editor](docs/editor.jpeg)

By using multiple layers, you can define connective rules on the first, and decorative rules on the other layers. All you do is "color code" the first socket layer with tiles from your tileset.
Each Pattern can only connect to other patterns with the same color rules on that particular side.

![rules](docs/sockets.jpeg)

Here you can see the socket layer, which just consists of 2 different tiles from your tileset. Beware, if you have patterns that cannot connect to any other pattern, the algorithm will fail.

## Final Words

This is a work in progress/demo addon and not production ready, there are bugs. I used this to generate the world in my [godot game](https://youtu.be/3B0e7ffAoKQ?t=48), but for reasons (Rust addict) I switched
to the bevy game engine. Would be a shame to let this go to waste, so I decided to share it with you.

I will not add any new features. If you want to contribute, feel free to do so. I'll do my best to help you out.
