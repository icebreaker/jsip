var AudioContext = window.AudioContext || window.webkitAudioContext;
var requestAnimationFrame =  window.requestAnimationFrame || 
                             window.webkitRequestAnimationFrame ||
                             window.mozRequestAnimationFrame ||
                             window.oRequestAnimationFrame ||
                             window.msRequestAnimationFrame ||
                             function(callback, element) { window.setTimeout(callback, 1000 / 60); };

var w = 532;
var h = 532;

var canvas = document.createElement('canvas');
canvas.width = w;
canvas.height = h;
document.body.appendChild(canvas);

var ctx = canvas.getContext('2d');

var image = ctx.getImageData(0, 0, w, h);
var pixels = image.data;

var ocx = w >> 1;
var ocy = h >> 1;
var r = 128;
var or2 = r * r;

var last = new Date();
var ticks = 0;

var audio_ctx = new AudioContext();

var output = audio_ctx.createGain();
var merger = audio_ctx.createChannelMerger();
merger.connect(output);

var c1 = audio_ctx.createOscillator();
c1.type = 'sine';
c1.frequency.value = 0;
c1.connect(merger, 0, 0);

var c2 = audio_ctx.createOscillator();
c2.type = 'sine';
c2.frequency.value = 0;
c2.connect(merger, 0, 1);

c1.start(0);
c2.start(0);

output.gain.value = 0.2;
output.connect(audio_ctx.destination);

canvas.oncontextmenu = function(e)
{
  e.preventDefault();

  c1.stop();
  c2.stop();

  return false;
};

function freq(f, b)
{
  var o = b / 2.0;
  c1.frequency.value = f - o;
  c2.frequency.value = f + o;
}

var freq_dt = 0;
var freq_delay = Math.random() * 1000;

function tick()
{
  var now = new Date();
  var dt = now - last;
  last = now;

  ticks += dt * 0.00001;

  freq_dt += dt;
  if(freq_dt > freq_delay)
  {
    freq_dt = 0;
    freq_delay = Math.random() * 2000;
    freq(100 + Math.random() * 200, Math.random() * 10);
  }

  var cx = ocx + (Math.sin(ticks * 32) * 64);
  var cy = ocy + (Math.cos(ticks * 32) * 64);

  var r2  = (or2 + Math.sin(ticks * 128) * 4096) * 2.0;

  for(var y = 0; y < h; y++)
  {
    var oy = y * w;

    for(var x = 0; x < w; x++)
    {
      var i = (x + oy) << 2;
      var j = 0;

      var dx = x - cx;
      var dy = y - cy;
      var d = dx * dx + dy * dy;

      if(d < (r2 * (Math.cos(x * ticks) * Math.sin(y * ticks))))
      {
        j = (Math.random() * 255) | 0;
        if(j < 128) j = 128;

        pixels[i + 0] = 0xff;
        pixels[i + 1] = j;
        pixels[i + 2] = 0x00;
        pixels[i + 3] = 0xff;
      }
      else
      {
        pixels[i + 0] = 0x00;
        pixels[i + 1] = 0x00;
        pixels[i + 2] = 0x00;
        pixels[i + 3] = 0xff;
      }
    }
  }

  ctx.putImageData(image, 0, 0);

  requestAnimationFrame(tick);
}

tick();
