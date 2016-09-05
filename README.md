JS "intro" Packer
=================
JSIP takes any piece of "JavaScript" and packs into a 100% valid PNG
image file, which is then "loaded" and "decoded" at run-time.

Unlike other similar "packers", it doesn't not rely on any custom
PNG chunks or other "hacks", as a result you can expect the actual 
"compressed" size to be slightly larger than usual.

Wasting a few bytes, for better compatibility, is totally acceptable.

Please keep in mind, that even with the indirect "eval", there's quite
a significant performance hit on the "evaluated" code.

Be sure to test the "result" in multiple browsers.

Usage
-----
```bash
./jsip.rb 2k.js > 2k.html
```

or

```bash
ruby jsip.rb 2k.js > 2k.html
```

or as a "library"

```ruby
require 'jsip'

File.open('hello_world.html', 'w') do |f|
  f.write(JSIP::HTML.format('hello world', JSIP::GrayScalePNG.new(JSIP::JS.clean('alert("hello world");'))))
end
```

Contribute
----------
* Fork the project.
* Make your feature addition or bug fix.
* Do **not** bump the version number.
* Send me a pull request. Bonus points for topic branches.

License
-------
Released into the Public Domain. No warranty implied. Use at your own risk.
