package;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import openfl.display.PNGEncoderOptions;

class PlayState extends FlxState
{
    var bg:FlxSprite;
    var image:FlxSprite;
    var info:FlxText;

    var ditherStrength:Int = 128;
    var ditherText:FlxText;

    override public function create()
    {
        super.create();

        bgColor = 0xFF202020;

        bg = new FlxSprite(0, 0);
        bg.loadGraphic("assets/images/editorBG.png");
        add(bg);

        image = new FlxSprite(0, 0);
        add(image);

        info = new FlxText(0, 10, FlxG.width,
            "Dither Editor - HaxeFlixel");
        info.setFormat(null, 24, 0xFFFFFFFF, "center");
        add(info);

        var loadBtn = new FlxButton(20, 60, "Load Image", loadImage);
        add(loadBtn);

        var ditherBtn = new FlxButton(180, 60, "Apply Dither", applyDither);
        add(ditherBtn);

        var exportBtn = new FlxButton(340, 60, "Export", exportImage);
        add(exportBtn);

        var minusBtn = new FlxButton(520, 60, "-", function()
        {
            ditherStrength -= 10;

            if (ditherStrength < 0)
                ditherStrength = 0;

            updateDitherText();
        });
        add(minusBtn);

        ditherText = new FlxText(590, 66, 200,
            "Strength: " + ditherStrength);
        ditherText.setFormat(null, 16, 0xFFFFFFFF);
        add(ditherText);

        var plusBtn = new FlxButton(770, 60, "+", function()
        {
            ditherStrength += 10;

            if (ditherStrength > 255)
                ditherStrength = 255;

            updateDitherText();
        });
        add(plusBtn);
    }

    function updateDitherText()
    {
        ditherText.text = "Strength: " + ditherStrength;
    }

    function loadImage()
    {
        var file = new FileReference();

        file.addEventListener(Event.SELECT, function(_)
        {
            file.load();
        });

        file.addEventListener(Event.COMPLETE, function(_)
        {
            var bytes:ByteArray = file.data;
            var bmp = BitmapData.fromBytes(bytes);

            image.loadGraphic(bmp);

            image.screenCenter();
        });

        file.browse();
    }

    function exportImage()
    {
        if (image.pixels == null)
            return;

        var file = new FileReference();

        var pngBytes = image.pixels.encode(
            image.pixels.rect,
            new PNGEncoderOptions()
        );

        file.save(pngBytes, "dither.png");
    }

    function applyDither()
{
    if (image.pixels == null)
        return;

    var original = image.pixels.clone();

    var smallW = Std.int(original.width / pixelSize);
    var smallH = Std.int(original.height / pixelSize);

    if (smallW < 1) smallW = 1;
    if (smallH < 1) smallH = 1;

    var pixelated = new BitmapData(smallW, smallH, false, 0x000000);

    pixelated.draw(original);

    var finalBmp = new BitmapData(
        original.width,
        original.height,
        false,
        0x000000
    );

    finalBmp.draw(pixelated, null, null, null,
        new Rectangle(0, 0, original.width, original.height), false);

    for (y in 0...finalBmp.height)
    {
        for (x in 0...finalBmp.width)
        {
            var pixel = finalBmp.getPixel(x, y);

            var r = (pixel >> 16) & 0xFF;
            var g = (pixel >> 8) & 0xFF;
            var b = pixel & 0xFF;

            var noise = ((x + y) % 2 == 0)
                ? ditherStrength
                : -ditherStrength;

            r = Std.int(Math.max(0, Math.min(255, r + noise)));
            g = Std.int(Math.max(0, Math.min(255, g + noise)));
            b = Std.int(Math.max(0, Math.min(255, b + noise)));

            finalBmp.setPixel(x, y,
                (r << 16) |
                (g << 8) |
                b);
        }
    }

    image.loadGraphic(finalBmp);

    image.screenCenter();
  }
}
