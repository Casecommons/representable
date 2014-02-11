require 'test_helper'

class GenericTest < MiniTest::Spec
# one day, this file will contain all engine-independent test cases. one day...
  let (:new_album)  { OpenStruct.new.extend(representer) }
  let (:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  let (:song) { OpenStruct.new(:title => "Resist Stance") }
  let (:song_representer) { Module.new do include Representable::Hash; property :title end  }


  describe "::collection" do
    representer! do
      collection :songs
    end

    it "doesn't initialize property" do
      new_album.from_hash({})
      new_album.songs.must_equal nil
    end

    it "leaves properties untouched" do
      album.from_hash({})
      # TODO: test property.
      album.songs.must_equal ["Fuck Armageddon"] # when the collection is not present in the incoming hash, this propery stays untouched.
    end


    # when collection is nil, it doesn't get rendered:
    for_formats(
      :hash => [Representable::Hash, {}],
      :xml  => [Representable::XML, "<open_struct></open_struct>"],
      :yaml => [Representable::YAML, "--- {}\n"], # FIXME: this doesn't look right.
    ) do |format, mod, output, input|

      describe "nil collections" do
        let (:format) { format }

        representer!(:module => mod) do
          collection :songs
          self.representation_wrap = :album if format == :xml
        end

        let (:album) { Album.new.extend(representer) }

        it "doesn't render collection in #{format}" do
          render(album).must_equal_document output
        end
      end
    end

    # when collection is set but empty, render the empty collection.
    for_formats(
      :hash => [Representable::Hash, {"songs" => []}],
      #:xml  => [Representable::XML, "<open_struct><songs/></open_struct>"],
      :yaml => [Representable::YAML, "---\nsongs: []\n"],
    ) do |format, mod, output, input|

      describe "empty collections" do
        let (:format) { format }

        representer!(:module => mod) do
          collection :songs
          self.representation_wrap = :album if format == :xml
        end

        let (:album) { OpenStruct.new(:songs => []).extend(representer) }

        it "renders empty collection in #{format}" do
          render(album).must_equal_document output
        end
      end
    end
  end


  describe "property with instance: { nil }" do # TODO: introduce :representable option?
    representer!(:inject => :song_representer) do
      property :song, :instance => lambda { |*| nil }, :extend => song_representer
    end

    let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) }

    it "calls #to_hash on song instance, nothing else" do
      hit.to_hash.must_equal("song"=>{"title"=>"Resist Stance"})
    end

    it "calls #from_hash on the existing song instance, nothing else" do
      song_id = hit.song.object_id
      hit.from_hash("song"=>{"title"=>"Suffer"})
      hit.song.title.must_equal "Suffer"
      hit.song.object_id.must_equal song_id
    end
  end


  for_formats(
    :hash => [Representable::Hash, {"song"=>{"title"=>"Resist Stance"}}, {"song"=>{"title"=>"Suffer"}}],
    :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><song><title>Suffer</title></song></open_struct>",],
    :yaml => [Representable::YAML, "---\nsong:\n  title: Resist Stance\n", "---\nsong:\n  title: Suffer\n"],
  ) do |format, mod, output, input|

    describe "[#{format}] property with parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }

      representer!(:module => mod, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        property :song, :parse_strategy => :sync, :extend => song_representer
      end

      let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) }

      it "calls #to_hash on song instance, nothing else" do
        render(hit).must_equal_document(output)
      end


      it "calls #from_hash on the existing song instance, nothing else" do
        song_id = hit.song.object_id

        parse(hit, input)

        hit.song.title.must_equal "Suffer"
        hit.song.object_id.must_equal song_id
      end
    end
  end

  # FIXME: there's a bug with XML and the collection name!
  for_formats(
    :hash => [Representable::Hash, {"songs"=>[{"title"=>"Resist Stance"}]}, {"songs"=>[{"title"=>"Suffer"}]}],
    #:json => [Representable::JSON, "{\"song\":{\"name\":\"Alive\"}}", "{\"song\":{\"name\":\"You've Taken Everything\"}}"],
    :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><songs><title>Suffer</title></songs></open_struct>"],
    :yaml => [Representable::YAML, "---\nsongs:\n- title: Resist Stance\n", "---\nsongs:\n- title: Suffer\n"],
  ) do |format, mod, output, input|

    describe "[#{format}] collection with :parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }
      representer!(:module => mod, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        collection :songs, :parse_strategy => :sync, :extend => song_representer
      end

      let (:album) { OpenStruct.new(:songs => [song]).extend(representer) }

      it "calls #to_hash on song instances, nothing else" do
        render(album).must_equal_document(output)
      end

      it "calls #from_hash on the existing song instance, nothing else" do
        collection_id = album.songs.object_id
        song          = album.songs.first
        song_id       = song.object_id

        parse(album, input)

        album.songs.first.title.must_equal "Suffer"
        song.title.must_equal "Suffer"
        #album.songs.object_id.must_equal collection_id # TODO: don't replace!
        song.object_id.must_equal song_id
      end
    end
  end


  # Lonely Collection
  require "representable/hash/collection"

  for_formats(
    :hash => [Representable::Hash::Collection, [{"title"=>"Resist Stance"}], [{"title"=>"Suffer"}]],
    # :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><songs><title>Suffer</title></songs></open_struct>"],
  ) do |format, mod, output, input|

    describe "[#{format}] lonely collection with :parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }
      representer!(:module => Representable::Hash, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        items :parse_strategy => :sync, :extend => song_representer
      end

      let (:album) { [song].extend(representer) }

      it "calls #to_hash on song instances, nothing else" do
        render(album).must_equal_document(output)
      end

      it "calls #from_hash on the existing song instance, nothing else" do
        #collection_id = album.object_id
        song          = album.first
        song_id       = song.object_id

        parse(album, input)

        album.first.title.must_equal "Suffer"
        song.title.must_equal "Suffer"
        song.object_id.must_equal song_id
      end
    end
  end

  describe "mix :extend and inline representers" do
    representer! do
      rpr_module = Module.new do
        include Representable::Hash
        property :title
      end
      property :song, :extend => rpr_module do
        property :artist
      end
    end

    it do OpenStruct.new(:song => OpenStruct.new(:title => "The Fever And The Sound", :artist => "Strung Out")).extend(representer).
      to_hash.
      must_equal({"song"=>{"artist"=>"Strung Out", "title"=>"The Fever And The Sound"}})
    end
  end
end