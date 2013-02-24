require 'ostruct'
require 'rmagick'

module TileUp

  class Tiler

    def initialize(image_filename, options)
      default_options = {
        auto_zoom_levels: nil,
        tile_width: 256,
        tile_height: 256,
        filename_prefix: "map_tile",
        output_dir: "."
      }
      @options = OpenStruct.new(default_options.merge(options))

      @image = Magick::Image::read(image_filename).first
      @extension = image_filename.split(".").last
      @filename_prefix = @options.filename_prefix

      puts "Opened #{image_filename}, #{@image.columns} x #{@image.rows}"

      # pre-process our inputs to work out what we're supposed to do
      tasks = []

      if @options.auto_zoom_levels.nil?
        # if we have no auto zoom request, then
        # we dont shrink or scale, and save directly to the output
        # dir.
        tasks << {
          output_dir: @options.output_dir, # normal output dir
          scale: 1.0 # dont scale
        }
      else
        # do have zoom levels, so construct those tasks
        zoom_name = 20
        scale = 1.0
        tasks << {
          output_dir: File.join(@options.output_dir, zoom_name.to_s),
          scale: scale
        }
        (@options.auto_zoom_levels-1).times do |level|
          scale = scale / 2.0
          zoom_name = zoom_name - 1
          tasks << {
            output_dir: File.join(@options.output_dir, zoom_name.to_s),
            scale: scale
          }
        end

        # run through tasks list
        tasks.each do |task|
          image = @image
          image_path = File.join(task[:output_dir], @filename_prefix)
          if task[:scale] != 1.0 
            # if scale required, scale image
            image = @image.scale(task[:scale])
          end
          # make output dir
          make_path(task[:output_dir])
          self.make_tiles(image, image_path, @options.tile_width, @options.tile_height)
        end
                
      end

      puts tasks

      # if(Dir::exists? @options[:output_dir] == false)
      #   Dir::mkdir(@options[:output_dir])
      # end

      # if @options[:auto_zoom_levels].nil? == false
      #   # do the first zoom level at 100% of the image size
      #   zoom_name = 20
      #   path = File.join(@options[:output_dir], zoom_name)
      #   Dir::mkdir(path)
      #   self.make_tiles(@image, File.join(path, "#{@filename_prefix}"), @options[:tile_width], @options[:tile_height])
      #   # now shrink the image by half and make that zoom level, repeat.
      #   scale = 0.5
      #   (@options[:auto_zoom_levels]-1).times do |level|
      #     zoom_name = zoom_name - 1
      #     scaled = @image.scale(scale)
      #     path = File.join(@options[:output_dir], zoom_name)
      #     Dir::mkdir(path)
      #     puts "Zoom level: #{zoom_name}, scaled size: #{scaled.columns} x #{scaled.rows}"
      #     self.make_tiles(scaled, File.join(path, "#{@filename_prefix}"), @options[:tile_width], @options[:tile_height])
      #     scale = scale / 2
      #   end
      # else
      #   Dir::mkdir(@options[:output_dir])
      #   # no auto zoom required, just split this one image directly.
      #   self.make_tiles(@image, File.join(@options[:output_dir], "#{@filename_prefix}"), @options[:tile_width], @options[:tile_height])
      # end
      
    end

    def make_path(directory_path)
      parts = directory_path.split(File::SEPARATOR);
      parts.each_index do |i|
        upto = parts[0..i].join(File::SEPARATOR)
        Dir::mkdir(upto) unless Dir::exists?(upto)
      end
    end

    def make_tiles(image, filename_prefix, tile_width, tile_height)
      # find image width and height
      # then find out how many tiles we'll get out of 
      # the image, then use that for the xy offset in crop.
      num_columns = image.columns/tile_width
      num_rows = image.rows/tile_height
      x,y,column,row = 0,0,0,0
      crops = []

      puts "Tiling... columns: #{num_columns}, rows: #{num_rows}"

      while true
        x = column * tile_width
        y = row * tile_height
        crops << {
          x: x,
          y: y,
          row: row,
          column: column
        }
        column = column + 1
        if column >= num_columns
          column = 0
          row = row + 1
        end
        if row >= num_rows
          break
        end
      end

      crops.each do |c|
        ci = image.crop(c[:x], c[:y], tile_width, tile_height, true);
        puts "Saving tile: #{c[:x]}, #{c[:y]}..."
        ci.write("#{filename_prefix}_#{c[:column]}_#{c[:row]}.#{@extension}")
        puts "Saved."
        ci = nil
      end
    end

    puts "Tiled."
  
  end

end