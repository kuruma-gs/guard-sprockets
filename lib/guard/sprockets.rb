require 'guard'
require 'guard/guard'
require 'erb'

require 'sprockets'

module Guard
  class Sprockets < Guard
    def initialize(watchers=[], options={})
      super(watchers,options)
      
      # init Sprocket env for use later
      @sprockets_env = ::Sprockets::Environment.new
      
      @asset_paths = options.delete(:asset_paths) || []
      @main_files = options.delete(:main_files) || []
      # add the asset_paths to the Sprockets env
      @asset_paths.each do |p|
        @sprockets_env.append_path p
      end
      # store the output destination
      @destination = options.delete(:destination)
      @opts = options
    end

    def start
       UI.info "Guard-Sprockets activated..."
       UI.info " -- external asset paths = [#{@asset_paths.inspect}]" unless @asset_paths.empty?
       UI.info " -- destination path = [#{@destination.inspect}]"
       UI.info "Guard-Sprockets is ready and waiting for some file changes..."
       run_all
    end
    
    def run_all
      run_on_change(@main_files)
    end

    def run_on_change(paths)
      compile_dirs = paths.map{|p| p.gsub(/\/.*/,"")}.uniq
      UI.info "Guard-Sprockets catched #{compile_dirs} updates"
      @main_files.each do |f| 
        sprocketize(f) if compile_dirs.include? f.gsub(/\/.*/,"")
      end
      true
    end
    
    private
    
    def sprocketize(path)
      changed = Pathname.new(path)

      @sprockets_env.append_path changed.dirname

      output_basename = changed.basename.to_s
      if match = output_basename.match(/^(.*\.(?:js|css))\.[^.]+$/)
        output_basename = match[1]
      end

      output_file = Pathname.new(File.join(@destination, output_basename))
      UI.info "Guard-Sprockets started compiling #{output_file}"
      FileUtils.mkdir_p(output_file.parent) unless output_file.parent.exist?
      output_file.open('w') do |f|
        f.write @sprockets_env[output_basename]
      end
      UI.info "Guard-Sprockets finished compiling #{output_file}"
    rescue => e
      UI.info "Guard-Sprockets error"
      UI.info "---------------------"
      UI.info e
      UI.info "---------------------"
    end
  end
end
