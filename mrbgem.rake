MRuby::Gem::Specification.new 'mruby-bin-picoruby' do |spec|
  spec.license = 'MIT'
  spec.author  = 'HASUMI Hitoshi'
  spec.summary = 'picoruby executable'
  spec.add_dependency 'mruby-pico-compiler', github: 'hasumikin/mruby-pico-compiler'

  mrubyc_dir = "#{build.gem_clone_dir}/mrubyc"
  spec.cc.include_paths << "#{mrubyc_dir}/src"

  mrubyc_srcs = %w(alloc    c_math     c_range   console  keyvalue  rrt0    vm
                   c_array  c_numeric  c_string  error    load      symbol
                   c_hash   c_object   class     global   value   hal_posix/hal)
  mrubyc_objs = mrubyc_srcs.map do |src|
    objfile("#{build_dir}/tools/mrubyc/src/#{src}")
  end

  mrubyc_objs.each_with_index do |mrubyc_obj, index|
    file mrubyc_obj => "#{mrubyc_dir}/src/#{mrubyc_srcs[index]}.c" do |f|
      cc.run f.name, "#{mrubyc_dir}/src/#{mrubyc_srcs[index]}.c"
    end
    file "#{mrubyc_dir}/src/#{mrubyc_srcs[index]}.c" => mrubyc_dir
  end

  directory build.gem_clone_dir

  file mrubyc_dir => build.gem_clone_dir do
    FileUtils.cd build.gem_clone_dir do
      unless Dir.exists? mrubyc_dir
        sh "git clone -b mrubyc3 https://github.com/mrubyc/mrubyc.git"
      end
    end
  end

  mrblib_obj = "#{build_dir}/tools/mrubyc/mrblib.o"

  file mrblib_obj => "#{mrubyc_dir}/src/mrblib.c" do |f|
    cc.run f.name, f.prerequisites.first
  end

  file "#{mrubyc_dir}/src/mrblib.c" => mrubyc_dir do |f|
    mrblib_sources = Dir.glob("#{mrubyc_dir}/mrblib/*.rb").join(' ')
    sh "#{build.mrbcfile} -B mrblib_bytecode -o #{mrubyc_dir}/src/mrblib.c #{mrblib_sources}"
  end

  picoruby_src = "#{dir}/tools/picoruby/picoruby.c"
  picoruby_obj = objfile(picoruby_src.pathmap("#{build_dir}/tools/picoruby/%n"))

  file picoruby_obj => "#{dir}/tools/picoruby/picoruby.c" do |f|
    Dir.glob("#{dir}/tools/picoruby/*.c").map do |f|
      cc.run objfile(f.pathmap("#{build_dir}/tools/picoruby/%n")), f
    end
  end

  pico_compiler_srcs = %w(common compiler dump generator mrbgem my_regex
                          node regex scope stream token tokenizer)
  pico_compiler_objs = pico_compiler_srcs.map do |name|
    objfile("#{build.gems['mruby-pico-compiler'].build_dir}/src/#{name}")
  end

  exec = exefile("#{build.build_dir}/bin/picoruby")

  file exec => mrubyc_objs + pico_compiler_objs + [mrblib_obj, picoruby_obj] do |f|
    build.linker.run f.name, f.prerequisites
  end

  build.bins << 'picoruby'
end
