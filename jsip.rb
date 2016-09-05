#!/usr/bin/env ruby

#
# JS "intro" Packer by Mihail Szabolcs
# Released into the Public Domain. No warranty implied. Use at your own risk.
# See: http://www.pouet.net/topic.php?which=8770
#

require 'zlib'

module JSIP
  VERSION = '1.0.0'.freeze

  class GrayScalePNG
    class Chunk
      attr_reader :tag, :bytes

      def initialize(tag, data)
        self.tag = tag
        self.bytes = [data.size, tag, data, Zlib::crc32(tag + data)].pack('NA4A*N')
      end

      private

      attr_writer :tag, :bytes
    end

    class HeaderChunk < Chunk
      HEADER = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].freeze

      def initialize(w, h)
        super('IHDR', [w, h, 8, 0, 0, 0, 0].pack('NNccccc'))
        self.bytes = [HEADER.pack('C*'), self.bytes].join
      end
    end

    class DataChunk < Chunk
      def initialize(data, level = 9)
        super('IDAT', Zlib::Deflate.deflate(data, level))
      end
    end

    class EndChunk < Chunk
      def initialize
        super('IEND', '')
      end
    end

    class Scanlines
      attr_reader :lines, :size, :bytes

      def initialize(data, w)
        self.lines = convert(data, w)
        self.size  = self.lines.size
        self.bytes = self.lines.join
      end

      private

      attr_writer :lines, :size, :bytes

      def convert(data, w)
        lines = data.bytes.each_slice(w).to_a
        lines.last.fill(0x20, lines.last.size...w)
        lines.map { |line| line.unshift(0x00).pack('C*') }
      end
    end

    attr_reader :scanlines, :w, :h, :level, :bytes

    def initialize(data, w = 256, level = 9)
      self.scanlines = Scanlines.new(data, w)
      self.w = w
      self.h = scanlines.size
      self.level = level
      self.bytes = [HeaderChunk.new(self.w, self.h),
                    DataChunk.new(self.scanlines.bytes, self.level), 
                    EndChunk.new].map(&:bytes).join
    end

    def to_b64
      @_b64 ||= [self.bytes].pack('m')
    end

    attr_writer :scanlines, :w, :h, :level, :bytes
  end

  class JS
    class << self
      def clean(js)
        js.dup.tap do |s|
          s.gsub!(/\/\*.*?\*\//m, '') # nuke /* comment */
          s.gsub!(/\/\/.*?\n/, '') # nuke // comment
          s.gsub!(/\n/, '') # nuke all new lines
          s.gsub!(/\s{2,}/, ' ') # nuke 2 or more consecutive spaces
          s.strip! # nuke any leading or trailing spaces
        end
      end
    end
  end

  class HTML
    UNPACKER = <<-EOF
      this.remove();
      var c=document.createElement('canvas').getContext('2d');
      c.canvas.width=this.width;
      c.canvas.height=this.height;
      c.drawImage(this,0,0);
      var p=c.getImageData(0,0,this.width,this.height).data;
      var s='';for(var i=0;i<p.length;i+=4)s+=String.fromCharCode(p[i]);
      (1,eval)(s);
      //[]['filter']['constructor'](s)();
    EOF

    TEMPLATE = <<-EOF
<html>
  <head>
    <title>%s</title>
  </head>
  <body>
    <img src="data:image/png;base64,%s" 
         style="visibility: hidden; position: absolute; top: 0; left: 0;" 
         onload="%s" onerror="this.remove();" />
  </body>
</html>
    EOF

    class << self
      def format(title, png)
        TEMPLATE % [title, png.to_b64, JS.clean(UNPACKER)]
      end
    end
  end
end

if $0 == __FILE__
  def main(filename, w = 256, title = nil)
    title ||= File.basename(filename, File.extname(filename)).capitalize
    JSIP::HTML.format(title, JSIP::GrayScalePNG.new(JSIP::JS.clean(File.read(filename)), w.to_i))
  end

  if ARGV.size < 1
    puts "usage: %s file.js [width] [title]" % File.basename($0, File.extname($0))
    exit -1
  else
    puts main(*ARGV)
  end
end
