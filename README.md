# Backpack to Gollum

Port the data in your [Backpack](http://backpackit.com) account to a local [Gollum](https://github.com/github/gollum) wiki.

I hacked this up after I realized that Backpack won't let me download my own uploaded files via their [API](http://developer.37signals.com/backpack/).

# Usage

    git clone git://github.com/swaroopch/backpack_to_gollum.git
    cd backpack_to_gollum
    bundle install
    # Download the export.xml from <your-account>.backpackit.com/account/exports
    bundle exec ruby backpack_to_gollum.rb
    cd notes
    gollum
