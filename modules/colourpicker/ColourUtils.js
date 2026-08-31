.pragma library

const OPAQUE_ALPHA = 0.9995;

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const normaliseHue = degrees => ((degrees % 360) + 360) % 360;

const formatNumber = (value, precision) => value.toFixed(precision).replace(/\.?0+$/, "");

const hexByte = value =>
    Math.round(clamp(value, 0, 1) * 255)
        .toString(16)
        .padStart(2, "0")
        .toUpperCase();

const invalidColour = () => {
    valid: false;
};

function toHex(colour) {
    const rgb = `${hexByte(colour.r)}${hexByte(colour.g)}${hexByte(colour.b)}`;
    return `#${rgb}${colour.a < OPAQUE_ALPHA ? hexByte(colour.a) : ""}`;
}

function toRgb(colour) {
    const channels = [colour.r, colour.g, colour.b].map(channel => Math.round(channel * 255)).join(", ");
    return colour.a < OPAQUE_ALPHA ? `${channels}, ${formatNumber(colour.a, 2)}` : channels;
}

function toHsl(colour, fallbackHue) {
    const hue = colour.hslHue >= 0 ? colour.hslHue : fallbackHue;
    const channels = `${Math.round(hue * 360)}deg, ${Math.round(colour.hslSaturation * 100)}%, ${Math.round(colour.hslLightness * 100)}%`;
    return colour.a < OPAQUE_ALPHA ? `${channels}, ${formatNumber(colour.a, 2)}` : channels;
}

function toCmyk(colour) {
    const key = 1 - Math.max(colour.r, colour.g, colour.b);
    let cyan = 0;
    let magenta = 0;
    let yellow = 0;

    if (key < 0.999999) {
        cyan = (1 - colour.r - key) / (1 - key);
        magenta = (1 - colour.g - key) / (1 - key);
        yellow = (1 - colour.b - key) / (1 - key);
    }

    const channels = [cyan, magenta, yellow, key].map(channel => `${Math.round(channel * 100)}%`).join(", ");
    const alpha = colour.a < OPAQUE_ALPHA ? ` / ${Math.round(colour.a * 100)}%` : "";
    return `${channels}${alpha}`;
}

function srgbToLinear(channel) {
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
}

function linearToSrgb(channel) {
    return channel <= 0.0031308 ? channel * 12.92 : 1.055 * channel ** (1 / 2.4) - 0.055;
}

function toOklch(colour) {
    const red = srgbToLinear(colour.r);
    const green = srgbToLinear(colour.g);
    const blue = srgbToLinear(colour.b);

    const linearLightness = 0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue;
    const linearMagenta = 0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue;
    const linearS = 0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue;

    const lightnessRoot = Math.cbrt(linearLightness);
    const magentaRoot = Math.cbrt(linearMagenta);
    const sRoot = Math.cbrt(linearS);

    const lightness = 0.2104542553 * lightnessRoot + 0.793617785 * magentaRoot - 0.0040720468 * sRoot;
    const a = 1.9779984951 * lightnessRoot - 2.428592205 * magentaRoot + 0.4505937099 * sRoot;
    const b = 0.0259040371 * lightnessRoot + 0.7827717662 * magentaRoot - 0.808675766 * sRoot;
    const chroma = Math.sqrt(a * a + b * b);
    const hue = chroma < 0.000001 ? 0 : normaliseHue((Math.atan2(b, a) * 180) / Math.PI);
    const alpha = colour.a < OPAQUE_ALPHA ? ` / ${Math.round(colour.a * 100)}%` : "";

    return `${formatNumber(lightness * 100, 1)}% ${formatNumber(chroma, 3)} ${formatNumber(hue, 1)}${alpha}`;
}

function parsePercentage(token) {
    const text = token.trim();
    if (!text.endsWith("%")) return NaN;

    const value = Number(text.slice(0, -1));
    if (!isFinite(value) || value < 0 || value > 100) return NaN;
    return value / 100;
}

function parseAlpha(token) {
    if (token === undefined || token === null || token === "") return 1;

    const text = token.trim();
    const value = text.endsWith("%") ? parsePercentage(text) : Number(text);
    if (!isFinite(value) || value < 0 || value > 1) return NaN;
    return value;
}

function parseRgbChannel(token) {
    const text = token.trim();
    const value = text.endsWith("%") ? parsePercentage(text) : Number(text) / 255;
    if (!isFinite(value) || value < 0 || value > 1) return NaN;
    return value;
}

function parseHue(token) {
    const text = token.trim().toLowerCase();
    let degrees;

    if (text.endsWith("turn")) degrees = Number(text.slice(0, -4)) * 360;
    else if (text.endsWith("grad")) degrees = Number(text.slice(0, -4)) * 0.9;
    else if (text.endsWith("rad")) degrees = (Number(text.slice(0, -3)) * 180) / Math.PI;
    else if (text.endsWith("deg")) degrees = Number(text.slice(0, -3));
    else degrees = Number(text);

    return isFinite(degrees) ? normaliseHue(degrees) : NaN;
}

function splitFunctionBody(body) {
    const slashParts = body.split("/");
    if (slashParts.length > 2) return null;

    const values = slashParts[0].includes(",")
        ? slashParts[0].split(",").map(value => value.trim())
        : slashParts[0].trim().split(/\s+/);
    return {
        values,
        alpha: slashParts.length === 2 ? slashParts[1].trim() : null
    };
}

function colourResult(red, green, blue, alpha) {
    if (![red, green, blue, alpha].every(value => isFinite(value))) return invalidColour();

    return {
        valid: true,
        red: clamp(red, 0, 1),
        green: clamp(green, 0, 1),
        blue: clamp(blue, 0, 1),
        alpha: clamp(alpha, 0, 1)
    };
}

function parseFunction(text, expression, channelCount, convert, allowLegacyAlpha = true) {
    const match = text.match(expression);
    if (!match) return null;

    const body = splitFunctionBody(match[1]);
    if (!body) return invalidColour();

    if (allowLegacyAlpha && body.values.length === channelCount + 1 && body.alpha === null)
        body.alpha = body.values.pop();
    if (body.values.length !== channelCount) return invalidColour();

    return convert(body.values, parseAlpha(body.alpha));
}

function parseHex(text) {
    const match = text.match(/^#?([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i);
    if (!match) return null;

    let digits = match[1];
    if (digits.length <= 4)
        digits = digits
            .split("")
            .map(digit => digit + digit)
            .join("");

    return colourResult(
        Number.parseInt(digits.slice(0, 2), 16) / 255,
        Number.parseInt(digits.slice(2, 4), 16) / 255,
        Number.parseInt(digits.slice(4, 6), 16) / 255,
        digits.length === 8 ? Number.parseInt(digits.slice(6, 8), 16) / 255 : 1
    );
}

function parseRgb(text) {
    return parseFunction(text, /^rgba?\((.*)\)$/i, 3, (channels, alpha) =>
        colourResult(parseRgbChannel(channels[0]), parseRgbChannel(channels[1]), parseRgbChannel(channels[2]), alpha)
    );
}

function hslToRgb(hue, saturation, lightness, alpha) {
    const chroma = (1 - Math.abs(2 * lightness - 1)) * saturation;
    const section = hue / 60;
    const intermediate = chroma * (1 - Math.abs((section % 2) - 1));
    let red = 0;
    let green = 0;
    let blue = 0;

    if (section < 1) {
        red = chroma;
        green = intermediate;
    } else if (section < 2) {
        red = intermediate;
        green = chroma;
    } else if (section < 3) {
        green = chroma;
        blue = intermediate;
    } else if (section < 4) {
        green = intermediate;
        blue = chroma;
    } else if (section < 5) {
        red = intermediate;
        blue = chroma;
    } else {
        red = chroma;
        blue = intermediate;
    }

    const offset = lightness - chroma / 2;
    return colourResult(red + offset, green + offset, blue + offset, alpha);
}

function parseHsl(text) {
    return parseFunction(text, /^hsla?\((.*)\)$/i, 3, (channels, alpha) =>
        hslToRgb(parseHue(channels[0]), parsePercentage(channels[1]), parsePercentage(channels[2]), alpha)
    );
}

function parseCmyk(text) {
    return parseFunction(text, /^(?:device-)?cmyk\((.*)\)$/i, 4, (channels, alpha) => {
        const cyan = parsePercentage(channels[0]);
        const magenta = parsePercentage(channels[1]);
        const yellow = parsePercentage(channels[2]);
        const key = parsePercentage(channels[3]);
        return colourResult((1 - cyan) * (1 - key), (1 - magenta) * (1 - key), (1 - yellow) * (1 - key), alpha);
    });
}

function oklchToRgb(lightness, chroma, hue, alpha) {
    const angle = (hue * Math.PI) / 180;
    const a = chroma * Math.cos(angle);
    const b = chroma * Math.sin(angle);

    const lightnessRoot = lightness + 0.3963377774 * a + 0.2158037573 * b;
    const magentaRoot = lightness - 0.1055613458 * a - 0.0638541728 * b;
    const sRoot = lightness - 0.0894841775 * a - 1.291485548 * b;

    const linearLightness = lightnessRoot ** 3;
    const linearMagenta = magentaRoot ** 3;
    const linearS = sRoot ** 3;

    const red = linearToSrgb(4.0767416621 * linearLightness - 3.3077115913 * linearMagenta + 0.2309699292 * linearS);
    const green = linearToSrgb(-1.2684380046 * linearLightness + 2.6097574011 * linearMagenta - 0.3413193965 * linearS);
    const blue = linearToSrgb(-0.0041960863 * linearLightness - 0.7034186147 * linearMagenta + 1.707614701 * linearS);
    return colourResult(red, green, blue, alpha);
}

function parseOklch(text) {
    return parseFunction(
        text,
        /^oklch\((.*)\)$/i,
        3,
        (channels, alpha) => {
            const lightnessText = channels[0];
            const lightness = lightnessText.endsWith("%") ? parsePercentage(lightnessText) : Number(lightnessText);
            const chroma = Number(channels[1]);
            const hue = parseHue(channels[2]);
            if (!isFinite(lightness) || lightness < 0 || lightness > 1 || !isFinite(chroma) || chroma < 0)
                return invalidColour();

            return oklchToRgb(lightness, chroma, hue, alpha);
        },
        false
    );
}

function parseColour(input) {
    const text = input.trim();
    if (!text) return invalidColour();

    const parsers = [parseHex, parseRgb, parseHsl, parseCmyk, parseOklch];
    for (const parser of parsers) {
        const result = parser(text);
        if (result !== null) return result;
    }

    return invalidColour();
}
